#!/usr/bin/env bash
set -euo pipefail

# fetch-upstream.sh: Download upstream source tarball for a specified package
# Usage: ./fetch-upstream.sh <package-name> [version]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE="${1:-}"
VERSION="${2:-}"

if [[ -z "$PACKAGE" ]]; then
  echo "Usage: $0 <package-name> [version]"
  exit 1
fi

PKG_DIR="$REPO_ROOT/packages/$PACKAGE"
if [[ ! -d "$PKG_DIR" ]]; then
  echo "Error: Package directory $PKG_DIR does not exist"
  exit 1
fi

mkdir -p "$REPO_ROOT/build/sources"
BUILD_SRC="$REPO_ROOT/build/sources"

case "$PACKAGE" in
  libtsm)
    VERSION="${VERSION:-4.8.0}"
    TARBALL="libtsm-${VERSION}.tar.gz"
    URL="https://github.com/kmscon/libtsm/archive/refs/tags/v${VERSION}.tar.gz"
    ORIG_TAR="libtsm_${VERSION}.orig.tar.gz"
    ;;
  kmscon)
    VERSION="${VERSION:-10.0.3}"
    TARBALL="kmscon-${VERSION}.tar.gz"
    URL="https://github.com/kmscon/kmscon/archive/refs/tags/v${VERSION}.tar.gz"
    ORIG_TAR="kmscon_${VERSION}.orig.tar.gz"
    ;;
  wlroots)
    VERSION="${VERSION:-0.20.2}"
    TARBALL="wlroots-${VERSION}.tar.gz"
    URL="https://gitlab.freedesktop.org/wlroots/wlroots/-/archive/${VERSION}/wlroots-${VERSION}.tar.gz"
    ORIG_TAR="wlroots_${VERSION}.orig.tar.gz"
    ;;
  labwc)
    VERSION="${VERSION:-0.20.2}"
    TARBALL="labwc-${VERSION}.tar.gz"
    URL="https://github.com/labwc/labwc/archive/refs/tags/${VERSION}.tar.gz"
    ORIG_TAR="labwc_${VERSION}.orig.tar.gz"
    ;;
  sfwbar)
    # sfwbar tags are like v1.0_beta17 -> Debian version 1.0~beta17
    VERSION="${VERSION:-1.0~beta17}"
    TAG_VER="${VERSION/~/}"
    TARBALL="sfwbar-${VERSION}.tar.gz"
    URL="https://github.com/LBCrion/sfwbar/archive/refs/tags/v${TAG_VER}.tar.gz"
    ORIG_TAR="sfwbar_${VERSION}.orig.tar.gz"
    ;;
  mpv)
    VERSION="${VERSION:-0.41.0}"
    TARBALL="mpv-${VERSION}.tar.gz"
    URL="https://github.com/mpv-player/mpv/archive/refs/tags/v${VERSION}.tar.gz"
    ORIG_TAR="mpv_${VERSION}.orig.tar.gz"
    ;;
  celluloid)
    VERSION="${VERSION:-0.29}"
    TARBALL="celluloid-${VERSION}.tar.gz"
    URL="https://github.com/celluloid-player/celluloid/archive/refs/tags/v${VERSION}.tar.gz"
    ORIG_TAR="celluloid_${VERSION}.orig.tar.gz"
    ;;
  fdk-aac)
    VERSION="${VERSION:-2.0.3}"
    TARBALL="fdk-aac-${VERSION}.tar.gz"
    URL="https://github.com/mstorsjo/fdk-aac/archive/refs/tags/v${VERSION}.tar.gz"
    ORIG_TAR="fdk-aac_${VERSION}.orig.tar.gz"
    ;;
  pipewire)
    VERSION="${VERSION:-1.6.9}"
    TARBALL="pipewire-${VERSION}.tar.gz"
    URL="https://gitlab.freedesktop.org/pipewire/pipewire/-/archive/${VERSION}/pipewire-${VERSION}.tar.gz"
    ORIG_TAR="pipewire_${VERSION}.orig.tar.gz"
    ;;
  *)
    echo "Unknown package: $PACKAGE"
    exit 1
    ;;
esac

echo "==> Fetching $PACKAGE $VERSION from $URL..."
TARGET_ORIG="$BUILD_SRC/$ORIG_TAR"

if [[ ! -f "$TARGET_ORIG" ]]; then
  curl -fsSL -o "$TARGET_ORIG" "$URL"
  echo "Downloaded $ORIG_TAR"
else
  echo "$ORIG_TAR already exists in $BUILD_SRC"
fi

echo "PACKAGE=$PACKAGE" > "$BUILD_SRC/$PACKAGE.env"
echo "VERSION=$VERSION" >> "$BUILD_SRC/$PACKAGE.env"
echo "ORIG_TAR=$ORIG_TAR" >> "$BUILD_SRC/$PACKAGE.env"
echo "SUCCESS: Fetched $PACKAGE $VERSION"
