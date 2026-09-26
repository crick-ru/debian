# wlroots (crick Debian backports)

Packaging for `wlroots` 0.20.2 on Debian 13 (trixie), restricted to the
backends a Wayland-only system needs.

> **Not built at the moment.** The `wlroots` job is disabled in CI, and `labwc`
> is disabled with it because it depends on wlroots. The packaging below is kept
> ready for the moment the build is re-enabled.

## Enabled

- Backends `drm` and `libinput` only: `-Dbackends=drm,libinput`.

## Disabled

- **Xwayland**: `-Dxwayland=disabled`.
- XCB error handling: `-Dxcb-errors=disabled`. Together with Xwayland being off,
  no `libxcb`/`libx11` build dependency is needed.
- CI matrix entry (temporarily, see the note above).

## Changed

- Patch `Revert-layer-shell-error-on-0-dimension-without-anchors.patch` reverts
  the upstream check that errored out on a zero-size layer surface without
  anchors — such surfaces are produced by panels and bars.
- Patch `trixie-relax-build-dependency-versions.patch` lowers the build
  requirements to what trixie actually ships: wayland 1.23.1 (upstream asks for
  1.24.0), libdrm 2.4.124 (asks 2.4.129), libxkbcommon 1.7.0 (asks 1.8.0) and
  wayland-protocols 1.44 (asks 1.47).
- Debug symbol packages (`-dbgsym`) are not built and not published.
