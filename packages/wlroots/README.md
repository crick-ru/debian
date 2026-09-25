# wlroots (Debian Trixie - Wayland Build)

Debian packaging recipe for `wlroots`, optimized for pure Wayland environments without legacy X11 / Xwayland dependencies.

- **Target OS**: Debian GNU/Linux 13 (trixie)
- **Architecture**: `amd64`
- **Component**: `main`
- **Maintainer**: crick <mail@crick.ru>

## Configuration Highlights

- X11 backend and Xwayland support disabled (`-Dbackends=drm,libinput -Dxwayland=disabled`).
- Removed all libxcb/x11 build dependencies.
