# celluloid (crick Debian backports)

Packaging for `celluloid` 0.29 on Debian 13 (trixie): the GTK4 front end for
`mpv`.

## Enabled

- Upstream defaults, nothing is reconfigured: the build is a plain
  `dh $@ --buildsystem=meson`.
- The front end talks to the Wayland-only `libmpv2` of this repository (see
  `packages/mpv/README.md`), which is the main reason to build it here.

## Disabled

- Nothing is disabled by this packaging.

## Changed

- Patch `01_use-appstreamcli.patch` builds the AppStream metadata with
  `appstreamcli`; the tool that upstream used (`appstream-util`) is no longer
  available in trixie.
- Debug symbol packages (`-dbgsym`) are not built and not published.
