# labwc (crick Debian backports)

Packaging for `labwc` 0.20.2 on Debian 13 (trixie): a small, scriptable Wayland
compositor.

> **Not built at the moment.** `labwc` needs `libwlroots-0.20` from this
> repository, and the `wlroots` job is currently disabled in CI, so `labwc` is
> excluded from the build matrix together with it. The packaging below is kept
> ready for the moment the wlroots build is re-enabled.

## Enabled

- The wlroots compositor library of this repository, i.e. DRM/libinput without
  Xwayland (see `packages/wlroots/README.md`).

## Disabled

- **Xwayland**: `-Dxwayland=disabled`. X11 clients need XWayland from elsewhere
  or a nested Wayland compositor.
- CI matrix entry (temporarily, see the note above).

## Changed

- No further changes against the upstream Debian packaging; the sources are
  overlaid on top of it by `scripts/build-package.sh`.
- Debug symbol packages (`-dbgsym`) are not built and not published.
