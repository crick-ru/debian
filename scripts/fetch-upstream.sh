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
  cairo)
    # Official release tarball from cairographics.org. Debian repacks the very
    # same archive (cairo_1.18.4.orig.tar.*), so the upstream version here is
    # the same; the tarball is taken as published, without the repack.
    VERSION="${VERSION:-1.18.6}"
    TARBALL="cairo-${VERSION}.tar.xz"
    URL="https://cairographics.org/releases/cairo-${VERSION}.tar.xz"
    ORIG_TAR="cairo_${VERSION}.orig.tar.xz"
    ;;
  ffmpeg)
    # Official release tarball; identical to Debian's ffmpeg_9.0.2.orig.tar.xz.
    # The Debian revision is 2, the version 9.0.2 and the epoch 7 (see below).
    VERSION="${VERSION:-9.0.2}"
    TARBALL="ffmpeg-${VERSION}.tar.xz"
    URL="https://ffmpeg.org/releases/ffmpeg-${VERSION}.tar.xz"
    ORIG_TAR="ffmpeg_${VERSION}.orig.tar.xz"
    ;;
  gstreamer1.0)
    # GStreamer core. All five source packages of the stack are released under
    # the same version number, which is what makes the -dev packages line up.
    VERSION="${VERSION:-1.28.7}"
    TARBALL="gstreamer-${VERSION}.tar.xz"
    URL="https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-${VERSION}.tar.xz"
    ORIG_TAR="gstreamer1.0_${VERSION}.orig.tar.xz"
    ;;
  gstreamer1.0-plugins-base)
    VERSION="${VERSION:-1.28.7}"
    TARBALL="gst-plugins-base-${VERSION}.tar.xz"
    URL="https://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-${VERSION}.tar.xz"
    ORIG_TAR="gstreamer1.0-plugins-base_${VERSION}.orig.tar.xz"
    ;;
  gstreamer1.0-plugins-good)
    VERSION="${VERSION:-1.28.7}"
    TARBALL="gst-plugins-good-${VERSION}.tar.xz"
    URL="https://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-${VERSION}.tar.xz"
    ORIG_TAR="gstreamer1.0-plugins-good_${VERSION}.orig.tar.xz"
    ;;
  gstreamer1.0-plugins-bad)
    VERSION="${VERSION:-1.28.7}"
    TARBALL="gst-plugins-bad-${VERSION}.tar.xz"
    URL="https://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-${VERSION}.tar.xz"
    ORIG_TAR="gstreamer1.0-plugins-bad_${VERSION}.orig.tar.xz"
    ;;
  gstreamer1.0-libav)
    VERSION="${VERSION:-1.28.7}"
    TARBALL="gst-libav-${VERSION}.tar.xz"
    URL="https://gstreamer.freedesktop.org/src/gst-libav/gst-libav-${VERSION}.tar.xz"
    ORIG_TAR="gstreamer1.0-libav_${VERSION}.orig.tar.xz"
    ;;
  wireplumber)
    # Session/policy manager for PipeWire. Built from the GitLab tag archive.
    # Needed by pwvucontrol, which requires wireplumber >= 0.5.11 while trixie
    # only has 0.5.8.
    VERSION="${VERSION:-0.5.17}"
    TARBALL="wireplumber-${VERSION}.tar.gz"
    URL="https://gitlab.freedesktop.org/pipewire/wireplumber/-/archive/${VERSION}/wireplumber-${VERSION}.tar.gz"
    ORIG_TAR="wireplumber_${VERSION}.orig.tar.gz"
    ;;
  pwvucontrol)
    # Volume control for PipeWire. Not packaged in Debian at all, so the
    # debian/ directory here is written from scratch. Upstream is Rust (cargo)
    # driven by meson and pulls its crates from crates.io at build time.
    VERSION="${VERSION:-0.5.3}"
    TARBALL="pwvucontrol-${VERSION}.tar.gz"
    URL="https://github.com/saivert/pwvucontrol/archive/refs/tags/${VERSION}.tar.gz"
    ORIG_TAR="pwvucontrol_${VERSION}.orig.tar.gz"
    ;;
  imagemagick)
    # Official release tarball from GitHub. Debian repacks it as +dfsg1, which
    # only exists for the versions Debian has uploaded; for the newest 7.1.2.x
    # the plain upstream tarball is used. Note the epoch 8 (see below).
    VERSION="${VERSION:-7.1.2-32}"
    TARBALL="ImageMagick-${VERSION}.tar.xz"
    URL="https://github.com/ImageMagick/ImageMagick/releases/download/${VERSION}/ImageMagick-${VERSION}.tar.xz"
    ORIG_TAR="imagemagick_${VERSION%%-*}.orig.tar.xz"
    ;;
  *)
    echo "Unknown package: $PACKAGE" >&2
    exit 1
    ;;
esac

# Debian revision of our build. apt only picks up a *newer* version, and the
# revision of the first published build of a package is 1, so every package
# whose debian/ was reworked afterwards needs revision 2 - otherwise a system
# that already has the first build would never receive the new one. Keep this
# list in sync with .clinerules/project.md.
REVISION=1
case "$PACKAGE" in
  # ffmpeg: first published build was made against FFmpeg 8.x options and
  # published 9.0.2 without the rework, so it already carries revision 2.
  ffmpeg) REVISION=2 ;;
  # mpv: 2 was the rework of the packaging, 3 is optical discs + DVB + VDPAU off.
  mpv)    REVISION=3 ;;
  celluloid|fdk-aac|kmscon|labwc|libdrm|libtsm|libxkbcommon|pipewire|pixman|sfwbar|wayland|wayland-protocols|wlroots)
    REVISION=2
    ;;
esac

# Debian epoch of a package, empty for most of them. ffmpeg carries epoch 7 for
# historical reasons: without it our version 9.0.2-2+crick would be *older*
# than the trixie 7:7.1.5 and apt would never pick it up, because the epoch is
# compared first. imagemagick carries epoch 8 for the same reason: trixie ships
# 8:7.1.1.43+dfsg1, so our 7.1.2-32-1+crick without an epoch would sort as
# older and apt would ignore the upgrade entirely.
EPOCH=""
case "$PACKAGE" in
  ffmpeg)     EPOCH="7" ;;
  imagemagick) EPOCH="8" ;;
esac

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

echo "PACKAGE=$PACKAGE" > "$BUILD_SRC/$PACKAGE.env"
echo "VERSION=$VERSION" >> "$BUILD_SRC/$PACKAGE.env"
echo "REVISION=$REVISION" >> "$BUILD_SRC/$PACKAGE.env"
echo "ORIG_TAR=$ORIG_TAR" >> "$BUILD_SRC/$PACKAGE.env"
echo "SUCCESS: Fetched $PACKAGE $VERSION-$REVISION+crick"
