# kmscon (crick Debian backports)

Packaging for `kmscon` 10.0.3 on Debian 13 (trixie): a terminal emulator that
runs directly on the DRM/KMS console, without any X11 involvement.

## Enabled

- All upstream autotools features: `--auto-features=enabled`.
- Documentation and man pages (docbook). They are switched off automatically for
  the `nodoc` build profile (`-Ddocs=disabled`).
- Console switching service `kmsconvt@`, shipped alongside the emulator.

## Disabled

- `-Dwerror=false`: warnings of newer GCC compilers must not break the build.
- Test suite (`override_dh_auto_test` is empty): the tests are interactive and
  require root, so they are not run during packaging.
- X11 is neither used nor declared as a dependency.

## Changed

- The install step stages everything into `debian/tmp`
  (`dh_auto_install --destdir=debian/tmp`), which is how the upstream packaging
  separates the files of the single binary package.
- `DEB_CFLAGS_MAINT_APPEND := -Wno-error=array-bounds` silences a known false
  positive coming from the bundled `libtsm` headers.
- `SYSTEMD_SYSTEM_UNIT_DIR` is taken from `pkg-config systemd` instead of being
  hardcoded, so the units land in the right directory on trixie.
- Patch `0001-Change-kmsconvt-.service-to-match-getty-.service.patch` renames
  `kmsconvt@.service` so that it is a drop-in match for `getty.service`.
- Patch `0002-Do-not-use-git-describe-to-generate-version.patch` stops meson from
  calling `git describe` (the release tarball carries no git metadata).
- `debian/kmscon.install` uses `dh-exec`, so the file must keep its executable
  bit — otherwise `dh_install` parses the `=>` line itself and fails with
  `Cannot find (any matches for) "=>"`.
- Debug symbol packages (`-dbgsym`) are not built and not published.
