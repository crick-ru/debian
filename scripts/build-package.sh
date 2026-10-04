#!/usr/bin/env bash
set -euo pipefail

# build-package.sh: Unpack source tarball, overlay debian/ directory, update changelog and build .deb packages
# Usage: ./build-package.sh <package-name> [--source-only] [extra dpkg-buildpackage args]
#
# --source-only builds just the source package (.dsc): dpkg-buildpackage -S
# applies quilt patches to the real tarball, runs debian/rules clean, parses
# control/changelog and produces the .dsc - without compiling anything.
# tools/local-source-check.sh uses it as the pre-CI packaging check.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE="${1:-}"
shift || true

if [[ -z "$PACKAGE" ]]; then
  echo "Usage: $0 <package-name> [--source-only] [extra dpkg-buildpackage args]"
  exit 1
fi

# Peel --source-only off; everything else goes to dpkg-buildpackage unchanged.
SOURCE_ONLY=0
DPKG_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--source-only" ]]; then
    SOURCE_ONLY=1
  else
    DPKG_ARGS+=("$arg")
  fi
done

BUILD_SRC="$REPO_ROOT/build/sources"
ENV_FILE="$BUILD_SRC/$PACKAGE.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Fetching upstream source first..."
  "$SCRIPT_DIR/fetch-upstream.sh" "$PACKAGE"
fi

# Load variables: VERSION, ORIG_TAR
# shellcheck source=/dev/null
source "$ENV_FILE"

BUILD_WORK="$REPO_ROOT/build/work/$PACKAGE"
rm -rf "$BUILD_WORK"
mkdir -p "$BUILD_WORK"

cd "$BUILD_WORK"

# Copy orig tarball to build work directory parent
cp "$BUILD_SRC/$ORIG_TAR" "$REPO_ROOT/build/work/"

# Пакеты с несколькими orig-тарболами (chromium: основной + orig-pre-gen).
# dpkg-source требует их рядом с исходным деревом, поэтому они копируются
# туда же. Список приходит из fetch-upstream.sh, который кладёт их в
# build/sources и перечисляет в <package>.env.
#
# Их нужно ещё и распаковать в дерево: у chromium второй тарбол содержит
# каталог pre-gen/ с файлами, которые генерируются во время сборки (bindgen,
# nodejs), и без них сборка падает на Debian stable. Основной тарбол
# распаковывается с --strip-components=1, дополнительные — без него: их
# внутренние пути значимы (pre-gen/<arch>/...), а верхний каталог у них уже
# именно тот, что нужен.
for extra in ${EXTRA_TARBALLS:-}; do
  cp "$BUILD_SRC/$extra" "$REPO_ROOT/build/work/"
done

# Extract tarball
echo "==> Extracting $ORIG_TAR..."
mkdir src-extracted
tar -xf "$BUILD_SRC/$ORIG_TAR" -C src-extracted --strip-components=1

mv src-extracted/* src-extracted/.* . 2>/dev/null || true
rmdir src-extracted || true

for extra in ${EXTRA_TARBALLS:-}; do
  echo "==> Extracting $extra..."
  tar -xf "$BUILD_SRC/$extra"
done

# Overlay debian/ directory from package definitions
echo "==> Overlaying debian/ directory for $PACKAGE..."
cp -r "$REPO_ROOT/packages/$PACKAGE/debian" ./

# Ensure source/format is 3.0 (quilt)
mkdir -p debian/source
echo "3.0 (quilt)" > debian/source/format

# Update the changelog with the version used for this backports build.
# The version string itself comes from pkg-version.sh (single source of truth).
TARGET_RELEASE="trixie"
DEB_VERSION="$("$SCRIPT_DIR/pkg-version.sh" "$PACKAGE")"
CHANGELOG_DATE="$(LC_ALL=C date -R)"

cat << CHLOG > debian/changelog.new
$PACKAGE ($DEB_VERSION) $TARGET_RELEASE; urgency=medium

  * Build for the crick Debian backports repository (Debian trixie, amd64).

 -- crick Debian Backports <backports@users.noreply.github.com>  $CHANGELOG_DATE

CHLOG

if [[ -f debian/changelog ]]; then
  cat debian/changelog >> debian/changelog.new
fi
mv debian/changelog.new debian/changelog

# Build the package. Debug symbol packages (-dbgsym) are not published in this
# repository: debhelper generates them automatically, so the generation is
# disabled via DEB_BUILD_OPTIONS. The rule is stated in the repository rules.
export DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS:+$DEB_BUILD_OPTIONS }noautodbgsym"
if (( SOURCE_ONLY )); then
  echo "==> Running dpkg-buildpackage -S for $PACKAGE (source-only, no compilation, DEB_BUILD_OPTIONS=$DEB_BUILD_OPTIONS)..."
  dpkg-buildpackage -us -uc -S "${DPKG_ARGS[@]}"
  echo "SUCCESS: Source package check passed for $PACKAGE (patches applied, debian/rules clean ran, .dsc built)"
  exit 0
fi
echo "==> Running dpkg-buildpackage for $PACKAGE (DEB_BUILD_OPTIONS=$DEB_BUILD_OPTIONS)..."
dpkg-buildpackage -us -uc -b "${DPKG_ARGS[@]}"

# Move generated .deb packages to repository output
OUTPUT_DIR="$REPO_ROOT/repo-pool"
mkdir -p "$OUTPUT_DIR"

echo "==> Collecting generated deb packages..."
shopt -s nullglob
for deb in ../*-dbgsym_*.deb; do
  echo "WARNING: discarding debug symbol package $(basename "$deb")"
  rm -f "$deb"
done
debs=()
for deb in ../*.deb; do
  debs+=("$deb")
done
if (( ${#debs[@]} > 0 )); then
  mv "${debs[@]}" "$OUTPUT_DIR/"
else
  echo "WARNING: dpkg-buildpackage produced no .deb packages for $PACKAGE"
fi

echo "SUCCESS: Built package $PACKAGE -> $OUTPUT_DIR"
