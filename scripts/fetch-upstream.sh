#!/usr/bin/env bash
set -euo pipefail

# fetch-upstream.sh: Download upstream source tarball for a specified package
# Usage: ./fetch-upstream.sh <package-name> [version]
#        ./fetch-upstream.sh --print-version <package-name>
#          Prints the upstream version of a package without downloading anything.
#        ./fetch-upstream.sh --print-revision <package-name>
#          Prints the Debian revision of our build (1 for an untouched
#          packaging, 2 or 3 after the packaging was reworked) without
#          downloading.
#        ./fetch-upstream.sh --print-epoch <package-name>
#          Prints the Debian epoch of a package, empty for all but ffmpeg.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PRINT_MODE=""
case "${1:-}" in
  --print-version)  PRINT_MODE="version";  PACKAGE="${2:-}"; VERSION="" ;;
  --print-revision) PRINT_MODE="revision"; PACKAGE="${2:-}"; VERSION="" ;;
  --print-epoch)    PRINT_MODE="epoch";    PACKAGE="${2:-}"; VERSION="" ;;
  *)                PACKAGE="${1:-}"; VERSION="${2:-}" ;;
esac

if [[ -z "$PACKAGE" ]]; then
  echo "Usage: $0 <package-name> [version]" >&2
  echo "       $0 --print-version <package-name>" >&2
  echo "       $0 --print-revision <package-name>" >&2
  echo "       $0 --print-epoch <package-name>" >&2
  exit 1
fi

PKG_DIR="$REPO_ROOT/packages/$PACKAGE"
if [[ ! -d "$PKG_DIR" ]]; then
  echo "Error: Package directory $PKG_DIR does not exist"
  exit 1
fi

mkdir -p "$REPO_ROOT/build/sources"
BUILD_SRC="$REPO_ROOT/build/sources"

# Per-package data lives in its own file, scripts/upstream/<pkg>.conf: the
# upstream version, the tarball name, the URL, the name dpkg-source expects for
# the orig tarball, the Debian revision of our build and the epoch.
#
# One file per package is not cosmetic. The CI cache keys hash exactly this file
# (see .github/actions/build-deb), so bumping the version of one package must not
# invalidate the build cache of the other 31. The previous layout - one giant
# `case` holding all 32 packages - did exactly that: touching a single version
# rebuilt the whole repository.
PKG_CONF="$SCRIPT_DIR/upstream/$PACKAGE.conf"
if [[ ! -f "$PKG_CONF" ]]; then
  echo "Error: no upstream data for package $PACKAGE (expected $PKG_CONF)" >&2
  echo "       Known packages: $(cd "$SCRIPT_DIR/upstream" && echo *.conf | sed 's/\.conf//g')" >&2
  exit 1
fi

# Defaults first, so a .conf that says nothing about REVISION or EPOCH keeps
# them. REVISION=1 is the revision of an untouched packaging; a package whose
# debian/ was reworked after the first publication carries 2 or 3, otherwise
# apt would sort the new build as older and never upgrade to it.
REVISION=1
EPOCH=""
# shellcheck source=/dev/null
source "$PKG_CONF"

for var in VERSION URL ORIG_TAR; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: $PKG_CONF does not set $var" >&2
    exit 1
  fi
done

if [[ -n "$PRINT_MODE" ]]; then
  case "$PRINT_MODE" in
    version)  echo "$VERSION" ;;
    revision) echo "$REVISION" ;;
    epoch)    echo "$EPOCH" ;;
  esac
  exit 0
fi

TARGET_ORIG="$BUILD_SRC/$ORIG_TAR"

echo "==> Fetching $PACKAGE $VERSION from $URL..."

if [[ ! -f "$TARGET_ORIG" ]]; then
  curl -fsSL -o "$TARGET_ORIG" "$URL"
  echo "Downloaded $ORIG_TAR"
else
  echo "$ORIG_TAR already exists in $BUILD_SRC"
fi

# Некоторые пакеты (пока только chromium) состоят из ДВУХ orig-тарболов:
# основного и дополнительного (у chromium - orig-pre-gen с файлами, которые
# генерируются во время сборки). dpkg-source требует их оба, и файл должен
# лежать в build/sources рядом с основным. Имена дополнительных файлов
# перечислены в .conf через EXTRA_TARBALLS (пробел-separated), их URL - через
# EXTRA_TARBALL_URLS в том же порядке.
extra_list=(${EXTRA_TARBALLS:-})
extra_urls=(${EXTRA_TARBALL_URLS:-})
if (( ${#extra_list[@]} != ${#extra_urls[@]} )); then
  echo "Error: $PKG_CONF: EXTRA_TARBALLS (${#extra_list[@]}) and EXTRA_TARBALL_URLS (${#extra_urls[@]}) differ in length" >&2
  exit 1
fi
for i in "${!extra_list[@]}"; do
  extra="${extra_list[$i]}"
  target="$BUILD_SRC/$extra"
  if [[ -f "$target" ]]; then
    echo "$extra already exists in $BUILD_SRC"
    continue
  fi
  echo "==> Fetching extra orig tarball $extra..."
  curl -fsSL -o "$target" "${extra_urls[$i]}"
  echo "Downloaded $extra"
done

echo "PACKAGE=$PACKAGE" > "$BUILD_SRC/$PACKAGE.env"
echo "VERSION=$VERSION" >> "$BUILD_SRC/$PACKAGE.env"
echo "REVISION=$REVISION" >> "$BUILD_SRC/$PACKAGE.env"
echo "ORIG_TAR=$ORIG_TAR" >> "$BUILD_SRC/$PACKAGE.env"
# Список дополнительных orig-тарболов (пусто у большинства пакетов). Без этой
# строки build-package.sh не скопирует их в рабочий каталог, и dpkg-source
# не найдёт второй исходный файл.
echo "EXTRA_TARBALLS=${EXTRA_TARBALLS:-}" >> "$BUILD_SRC/$PACKAGE.env"
echo "SUCCESS: Fetched $PACKAGE $VERSION-$REVISION+crick"
