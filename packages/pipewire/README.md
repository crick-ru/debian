# pipewire (crick Debian backports)

Packaging for `pipewire` 1.6.9 on Debian 13 (trixie). The build is tuned for
Wayland-only desktops: everything that is not needed there is switched off at
configure time, and the Bluetooth codecs are the reason to use this build at all.

## Enabled

- Bluetooth codecs: **AAC** (via `libfdk-aac` from this repository), aptX,
  LC3, LDAC, Opus, SBC, plus `bluez5-plc-spandsp`.
- ALSA bridge and service discovery: `pipewire-alsa`, `-Davahi=enabled`.
- `libffado`, `libmysofa`, ROC, LV2, SDL2 modules, ONNX Runtime (ML denoiser).
- Documentation, man pages and the test suite (`pipewire-tests`).
- User **and** system WirePlumber services (`pipewire-system-services`).

## Disabled

- **X11** — `-Dx11=disabled -Dx11-xfixes=disabled`: no X11 modules, no X11
  dependencies in the resulting packages.
- **JACK** — `-Djack=disabled`: `pipewire-jack` and `libspa-0.2-jack` are not
  built or shipped, and the `jack-tunnel`, `jackdbus-detect` and `netjack2`
  modules are left out of `libpipewire-0.3-modules`. JACK clients have to use a
  real JACK server instead of routing through pipewire.
- **V4L2** — `-Dv4l2=disabled`: `pipewire-v4l2` and the `spa-0.2/v4l2` plugin
  are not built.
- **libcamera** — `-Dlibcamera=disabled`: Debian trixie ships libcamera 0.4.0
  while pipewire 1.6.x requires >= 0.6.0 and uses the controls API introduced
  later, so the plugin cannot be built here.
- Vulkan, FFmpeg, snap, LC3plus, LDAC decoder.

**Consequence:** this build has no camera source at all (neither libcamera nor
V4L2). `pipewire-audio-client-libraries` is kept as a transitional package for
`pipewire-alsa` only.

## Changed

- Patch `0001-CVE-2026-14330.patch` backports the upstream fix for
  CVE-2026-14330 (`spa_alloca` with overflow and limit checks).
- `libspa-0.2-modules` ships without the `v4l2` and `jack` plugins,
  `libpipewire-0.3-modules` without the four jack-related modules.
- Debug symbol packages (`-dbgsym`) are not built and not published.
