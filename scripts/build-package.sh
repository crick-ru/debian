#!/usr/bin/env bash
set -euo pipefail

# build-package.sh: Unpack source tarball, overlay debian/ directory, update changelog and build .deb packages
# Usage: ./build-package.sh <package-name> [extra dpkg-buildpackage args]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE="${1:-}"
shift || true

if [[ -z "$PACKAGE" ]]; then
  echo "Usage: $0 <package-name> [extra dpkg-buildpackage args]"
  exit 1
fi

BUILD_SRC="$REPO_ROOT/build/sources"
ENV_FILE="$BUILD_SRC/$PACKAGE.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Fetching upstream source first..."
  "$SCRIPT_DIR/fetch-upstream.sh" "$PACKAGE"
fi

# Load variables: VERSION, ORIG_TAR
source "$ENV_FILE"

BUILD_WORK="$REPO_ROOT/build/work/$PACKAGE"
rm -rf "$BUILD_WORK"
mkdir -p "$BUILD_WORK"

cd "$BUILD_WORK"

# Copy orig tarball to build work directory parent
cp "$BUILD_SRC/$ORIG_TAR" "$REPO_ROOT/build/work/"

# Extract tarball
echo "==> Extracting $ORIG_TAR..."
mkdir src-extracted
tar -xf "$BUILD_SRC/$ORIG_TAR" -C src-extracted --strip-components=1

mv src-extracted/* src-extracted/.* . 2>/dev/null || true
rmdir src-extracted || true

# Overlay debian/ directory from package definitions
echo "==> Overlaying debian/ directory for $PACKAGE..."
cp -r "$REPO_ROOT/packages/$PACKAGE/debian" ./

# Ensure source/format is 3.0 (quilt)
mkdir -p debian/source
echo "3.0 (quilt)" > debian/source/format

# Update changelog to reflect our modern Wayland build version
TARGET_RELEASE="trixie"
DEB_VERSION="${VERSION}-1+wayland"
CHANGELOG_DATE="$(LC_ALL=C date -R)"

cat << CHLOG > debian/changelog.new
$PACKAGE ($DEB_VERSION) $TARGET_RELEASE; urgency=medium

  * Automated clean Wayland-only build for Debian trixie repository.
  * Stripped legacy X11, Xorg and Xwayland dependencies.

 -- crick <mail@crick.ru>  $CHANGELOG_DATE

CHLOG

if [[ -f debian/changelog ]]; then
  cat debian/changelog >> debian/changelog.new
fi
mv debian/changelog.new debian/changelog

# Build debian package.
# Debug symbol packages (-dbgsym) are not published in this repository: debhelper
# generates them automatically, so the generation is disabled via DEB_BUILD_OPTIONS.
# The rule is fixed in .clinerules/project.md.
export DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS:+$DEB_BUILD_OPTIONS }noautodbgsym"
echo "==> Running dpkg-buildpackage for $PACKAGE (DEB_BUILD_OPTIONS=$DEB_BUILD_OPTIONS)..."
dpkg-buildpackage -us -uc -b "$@"

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
