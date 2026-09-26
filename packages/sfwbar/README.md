# sfwbar (crick Debian backports)

Packaging for `sfwbar` 1.0~beta17 on Debian 13 (trixie): a floating taskbar for
Wayland compositors.

## Enabled

- Layer-shell and foreign-toplevel protocols, so the bar works with any
  compositor that supports them (Sway, Hyprland, …).
- Manual pages are generated at build time: `override_dh_auto_build` runs
  `rst2man` over `doc/*.rst`, so no pre-generated man pages are shipped from
  upstream.

## Disabled

- Nothing is disabled by this packaging; the X11 code paths of upstream are
  simply not reachable in a Wayland session and no X11 dependency ends up in
  the package.

## Changed

- Patch `0001-docs-fix-typos.patch` and `0002-config-fix-typos.patch`: typo
  fixes in the documentation and the example configuration.
- Patch `0003-fix-replace-python-with-python3-in-embedded-scripts.patch`: the
  embedded python helpers call `python3`, because `python` no longer exists in
  trixie.
- `override_dh_install` additionally drops `usr/share/sfwbar/icons/weather/LICENSE`,
  which is not redistributed in the package.
- Debug symbol packages (`-dbgsym`) are not built and not published.
