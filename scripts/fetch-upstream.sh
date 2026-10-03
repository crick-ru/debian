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
libheif)
    # Debian's own orig tarball, byte-for-byte the one dpkg-source expects.
    # Upstream lives at https://github.com/strukturag/libheif, but Debian ships
    # the plain release tarball without a repack suffix, so the upstream version
    # stays 1.23.4 (no +dfsg / +ds). Packaging is taken from Debian
    # libheif_1.23.4-1~deb13u1 (branch 1.23), i.e. the Security Team upload for
    # trixie, chosen over the sid one because it is the newest 1.23.4 already
    # adapted to trixie's dependencies (it drops heif-view, so libsdl2-dev is
    # not needed). The packaging is then reworked down to libheif1 +
    # libheif-dev with the codec plugins kept inside libheif1 - see
    # packages/libheif.
    VERSION="${VERSION:-1.23.4}"
    TARBALL="libheif-${VERSION}.tar.gz"
    URL="http://deb.debian.org/debian/pool/main/libh/libheif/libheif_${VERSION}.orig.tar.gz"
    ORIG_TAR="libheif_${VERSION}.orig.tar.gz"
    ;;
  pulseaudio)
    # Debian's own orig tarball: PulseAudio is repacked by Debian as +dfsg1
    # (non-DFSG bits are removed), so the upstream part of our version keeps the
    # +dfsg1 suffix and the orig tarball is taken from the Debian pool - an
    # upstream release tarball would not match the announced version. Packaging
    # is taken from trixie (pulseaudio_17.0+dfsg1-2), not from unstable: after
    # the 17.0 upload Debian went back to 16.1 in sid, so trixie is where the
    # packaging for the 17.0 line actually is. It is reworked into a
    # client-only build: no daemon, no X11 - see packages/pulseaudio.
    VERSION="${VERSION:-17.0+dfsg1}"
    TARBALL="pulseaudio-${VERSION}.tar.xz"
    URL="http://deb.debian.org/debian/pool/main/p/pulseaudio/pulseaudio_${VERSION}.orig.tar.xz"
    ORIG_TAR="pulseaudio_${VERSION}.orig.tar.xz"
    ;;
  aml)
    # Debian's own orig tarball (upstream tag archive, renamed). aml is packaged
    # by Debian with no repack suffix, so the upstream version stays 1.0.0. It is
    # needed because wayvnc 0.10.1 requires libaml-dev >= 1.0.0 and trixie only
    # has 0.3.0 (and ships it under a different name, libaml0t64).
    VERSION="${VERSION:-1.0.0}"
    TARBALL="aml-${VERSION}.tar.gz"
    URL="http://deb.debian.org/debian/pool/main/a/aml/aml_${VERSION}.orig.tar.gz"
    ORIG_TAR="aml_${VERSION}.orig.tar.gz"
    ;;
  neatvnc)
    # Debian's own orig tarball: neatvnc is repacked by Debian as +dfsg, so the
    # upstream part of our version keeps the +dfsg suffix. neatvnc is needed
    # because wayvnc 0.10.1 requires libneatvnc-dev >= 1.0.0 and trixie only has
    # 0.9.1+dfsg (shipped as libneatvnc0).
    VERSION="${VERSION:-1.0.1+dfsg}"
    TARBALL="neatvnc-${VERSION}.tar.xz"
    URL="http://deb.debian.org/debian/pool/main/n/neatvnc/neatvnc_${VERSION}.orig.tar.xz"
    ORIG_TAR="neatvnc_${VERSION}.orig.tar.xz"
    ;;
  wayvnc)
    # Debian's own orig tarball (upstream tag archive, renamed), no repack
    # suffix. Packaged from Debian (wayvnc_0.10.1-1) and reworked for this
    # repository: no man pages, no tests - see packages/wayvnc.
    VERSION="${VERSION:-0.10.1}"
    TARBALL="wayvnc-${VERSION}.tar.gz"
    URL="http://deb.debian.org/debian/pool/main/w/wayvnc/wayvnc_${VERSION}.orig.tar.gz"
    ORIG_TAR="wayvnc_${VERSION}.orig.tar.gz"
    ;;
  mesa)
    # Debian's own orig tarball of the trixie-backports upload of 26.1.6. The
    # backports packaging is used as the base rather than the sid one (26.2.4)
    # because 26.2.x needs llvm-22 and libdrm >= 2.4.134-3~, neither of which
    # trixie has; 26.1.6 builds against llvm-19 from trixie and against our
    # libdrm 2.4.134. Packaging is taken from Debian (mesa_26.1.6-1~bpo13+1,
    # branch 26.1) and reworked without X11 - see packages/mesa.
    VERSION="${VERSION:-26.1.6}"
    TARBALL="mesa-${VERSION}.tar.xz"
    URL="http://deb.debian.org/debian/pool/main/m/mesa/mesa_${VERSION}.orig.tar.xz"
    ORIG_TAR="mesa_${VERSION}.orig.tar.xz"
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
    #
    # "7.1.2-32" is ImageMagick's own upstream version (upstream numbers its
    # releases with a dash), so it stays in VERSION as is: our Debian revision
    # is REVISION below, and the binary version is 8:7.1.2-32-2+crick. The
    # orig tarball name must therefore keep the whole version - stripping the
    # "-32" made dpkg-source look for imagemagick_7.1.2.orig.tar.xz while the
    # changelog announces upstream 7.1.2-32, and the source build failed.
    VERSION="${VERSION:-7.1.2-32}"
    TARBALL="ImageMagick-${VERSION}.tar.xz"
    URL="https://github.com/ImageMagick/ImageMagick/releases/download/${VERSION}/ImageMagick-${VERSION}.tar.xz"
    ORIG_TAR="imagemagick_${VERSION}.orig.tar.xz"
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
# list in sync with the repository rules.
REVISION=1
case "$PACKAGE" in
  # ffmpeg: first published build was made against FFmpeg 8.x options and
  # published 9.0.2 without the rework, so it already carries revision 2.
  ffmpeg) REVISION=2 ;;
  # mpv: 2 was the rework of the packaging, 3 is optical discs + DVB + VDPAU off.
  mpv)    REVISION=3 ;;
  # imagemagick: 1 was published with the libheif delegate on, 2 was HEIF off,
  # 3 turns HEIF back on against the libheif1 of this repository.
  imagemagick) REVISION=3 ;;
  # sfwbar: 3 dropped the three quilt patches - by 1.0~beta17 upstream had
  # fixed the typos and switched the embedded scripts to python3 itself, so
  # they became no-ops and dpkg-source -b refused to build the source package.
  sfwbar) REVISION=3 ;;
  # pulseaudio: the trixie binary package is 17.0+dfsg1-2+b1, so revision 1
  # would sort as older and apt would never pick our client-only build up.
  pulseaudio) REVISION=2 ;;
  celluloid|fdk-aac|kmscon|labwc|libdrm|libtsm|libxkbcommon|pipewire|pixman|wayland|wayland-protocols|wlroots)
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
