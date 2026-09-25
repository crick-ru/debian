# mpv (Debian Trixie - Wayland Build)

Debian packaging recipe for `mpv`, optimized for pure Wayland environments without legacy X11 / Xwayland dependencies.

- **Target OS**: Debian GNU/Linux 13 (trixie)
- **Architecture**: `amd64`
- **Component**: `main`
- **Maintainer**: crick <mail@crick.ru>

## Configuration Highlights

- Pure Wayland video player (`-Dx11=disabled -Dwayland=enabled -Degl-wayland=enabled -Ddmabuf-wayland=enabled -Dvaapi-wayland=enabled`).
- Removed X11/XV/VDPAU-X11 dependencies.
