# libtsm (crick Debian backports)

Packaging for `libtsm` 4.8.0 on Debian 13 (trixie): the terminal state machine
library that `kmscon` is built on.

## Enabled

- Unit tests are built and can be run: `-Dtests=true`. The `nocheck` build
  profile switches them off (`-Dtests=false`).
- Both shared and static libraries, see the patch below.

## Disabled

- Nothing is disabled by this packaging.

## Changed

- Patch `0001-tsm-meson.build-Change-library-build-to-both_libraries.patch`
  builds `both_libraries` instead of shared only, so the static variant is
  available for other packages.
- `DPKG_GENSYMBOLS_CHECK_LEVEL := 4`: the generated symbol file must be complete
  for the `libtsm4` library.
- The documentation of `libtsm-dev` links to the one of `libtsm4`
  (`dh_installdocs -plibtsm-dev --link-doc=libtsm4`).
- Hardening flags are tightened: `DEB_BUILD_MAINT_OPTIONS := qa=+bug hardening=+all reproducible=+all`.
- Debug symbol packages (`-dbgsym`) are not built and not published.
