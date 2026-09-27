#!/usr/bin/env bash
set -euo pipefail

# fetch-upstream.sh: Download upstream source tarball for a specified package
# Usage: ./fetch-upstream.sh <package-name> [version]
#        ./fetch-upstream.sh --print-version <package-name>
#          Prints the upstream version of a package without downloading anything.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PRINT_VERSION_ONLY=false
if [[ "${1:-}" == "--print-version" ]]; then
  PRINT_VERSION_ONLY=true
  PACKAGE="${2:-}"
  VERSION=""
else
  PACKAGE="${1:-}"
  VERSION="${2:-}"
fi

if [[ -z "$PACKAGE" ]]; then
  echo "Usage: $0 <package-name> [version]" >&2
  echo "       $0 --print-version <package-name>" >&2
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
    # Upstream tags look like v1.0_beta17 (underscore), the Debian version is
    # written as 1.0~beta17 (tilde), so the tilde is turned back into "_".
    # The tilde has to be escaped as "\~": bash expands a bare "~" in the
    # pattern of ${VAR/pat/rep} into the home directory, and the substitution
    # silently does nothing.
    VERSION="${VERSION:-1.0~beta17}"
    TAG_VER="${VERSION/\~/_}"
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
  libdrm)
    # Tarball byte-for-byte identical to Debian's libdrm_2.4.134.orig.tar.xz.
    VERSION="${VERSION:-2.4.134}"
    TARBALL="libdrm-${VERSION}.tar.xz"
    URL="https://dri.freedesktop.org/libdrm/libdrm-${VERSION}.tar.xz"
    ORIG_TAR="libdrm_${VERSION}.orig.tar.xz"
    ;;
  pixman)
    # Tarball byte-for-byte identical to Debian's pixman_0.46.4.orig.tar.gz.
    VERSION="${VERSION:-0.46.4}"
    TARBALL="pixman-${VERSION}.tar.gz"
    URL="https://cairographics.org/releases/pixman-${VERSION}.tar.gz"
    ORIG_TAR="pixman_${VERSION}.orig.tar.gz"
    ;;
  wayland)
    # Official release tarball; identical to Debian's wayland_1.26.0.orig.tar.xz.
    VERSION="${VERSION:-1.26.0}"
    TARBALL="wayland-${VERSION}.tar.xz"
    URL="https://gitlab.freedesktop.org/wayland/wayland/-/releases/${VERSION}/downloads/wayland-${VERSION}.tar.xz"
    ORIG_TAR="wayland_${VERSION}.orig.tar.xz"
    ;;
  libxkbcommon)
    VERSION="${VERSION:-1.13.1}"
    TARBALL="libxkbcommon-${VERSION}.tar.gz"
    URL="https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-${VERSION}.tar.gz"
    ORIG_TAR="libxkbcommon_${VERSION}.orig.tar.gz"
    ;;
  wayland-protocols)
    # Version 1.47 is what wlroots 0.20.2 needs; the same version is available in
    # Debian's own trixie-backports (1.47-1~bpo13+1).
    VERSION="${VERSION:-1.47}"
    TARBALL="wayland-protocols-${VERSION}.tar.gz"
    URL="https://gitlab.freedesktop.org/wayland/wayland-protocols/-/archive/${VERSION}/wayland-protocols-${VERSION}.tar.gz"
    ORIG_TAR="wayland-protocols_${VERSION}.orig.tar.gz"
    ;;
  gtk+3.0)
    # Official release tarball; byte-for-byte identical to Debian's
    # gtk+3.0_3.24.52.orig.tar.xz (sha256 80931fa4…).
    VERSION="${VERSION:-3.24.52}"
    TARBALL="gtk-${VERSION}.tar.xz"
    URL="https://download.gnome.org/sources/gtk/3.24/gtk-${VERSION}.tar.xz"
    ORIG_TAR="gtk+3.0_${VERSION}.orig.tar.xz"
    ;;
  gtk4)
    # Official release tarball from GNOME. Debian repacks it as +ds, but that
    # repack only exists for the versions Debian has uploaded; for the newest
    # 4.22.x the plain tarball is used and the version stays 4.22.5.
    VERSION="${VERSION:-4.22.5}"
    TARBALL="gtk-${VERSION}.tar.xz"
    URL="https://download.gnome.org/sources/gtk/4.22/gtk-${VERSION}.tar.xz"
    ORIG_TAR="gtk4_${VERSION}.orig.tar.xz"
    ;;
  *)
    echo "Unknown package: $PACKAGE" >&2
    exit 1
    ;;
esac

if [[ "$PRINT_VERSION_ONLY" == true ]]; then
  echo "$VERSION"
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

echo "PACKAGE=$PACKAGE" > "$BUILD_SRC/$PACKAGE.env"
echo "VERSION=$VERSION" >> "$BUILD_SRC/$PACKAGE.env"
echo "ORIG_TAR=$ORIG_TAR" >> "$BUILD_SRC/$PACKAGE.env"
echo "SUCCESS: Fetched $PACKAGE $VERSION"
