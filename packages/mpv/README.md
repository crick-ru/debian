# mpv (crick Debian backports)

Packaging for `mpv` 0.41.0 on Debian 13 (trixie), built as a pure Wayland
player. The resulting packages contain no X11 libraries at all, which is what
makes the build differ from the distribution package.

## Enabled

- Wayland output and input: `-Dwayland=enabled`, `-Degl-wayland=enabled`.
- Zero-copy GPU rendering: `-Ddmabuf-wayland=enabled`.
- Hardware video decoding through VA-API on Wayland: `-Dvaapi-wayland=enabled`.
- libmpv client library: `-Dlibmpv=true` (used by `celluloid`).
- Optical disc and extras: `-Dcdda=enabled`, `-Ddvdnav=enabled`, and
  `-Ddvbin=enabled` on Linux hosts.

## Disabled

- **X11 and every X11 backend**: `-Dx11=disabled`, `-Degl-x11=disabled`,
  `-Dgl-x11=disabled`, `-Dvaapi-x11=disabled`, `-Dvdpau-gl-x11=disabled`,
  `-Dxv=disabled`, `-Dx11-clipboard=disabled`. The published `mpv` and
  `libmpv2` packages declare no `libx11*` dependency, so packages like
  `libxpresent1` are not pulled in.

## Changed

- `-Dbuild-date=false` keeps the build reproducible (no build timestamp).
- Debug symbol packages (`-dbgsym`) are not built and not published.
