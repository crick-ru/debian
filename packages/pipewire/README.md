# pipewire (Debian Trixie - Wayland Build)

Debian packaging recipe for `pipewire`, optimized for pure Wayland environments without legacy X11 / Xwayland dependencies.

- **Target OS**: Debian GNU/Linux 13 (trixie)
- **Architecture**: `amd64`
- **Component**: `non-free`
- **Maintainer**: crick <mail@crick.ru>

## Configuration Highlights

- Built with AAC Bluetooth codec support enabled (`libfdk-aac`, hosted in `non-free`).
- Legacy X11 module and dependencies disabled (`-Dx11=disabled -Dx11-xfixes=disabled`).
