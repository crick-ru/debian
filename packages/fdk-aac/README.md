# fdk-aac (crick Debian backports)

Packaging for `fdk-aac` 2.0.3 on Debian 13 (trixie): the Fraunhofer FDK AAC
library. It is the reason this repository is needed for Bluetooth audio — it
provides the AAC encoder/decoder that the pipewire Bluetooth module needs.

> The library is under a non-free licence (Fraunhofer). It is served from the
> single `backports` component of this repository.

## Enabled

- The command line encoder is built as well: `dh_auto_configure -- --enable-example`
  is what produces the `aac-enc` package.

## Disabled

- Nothing is disabled by this packaging.

## Changed

- Patch `add_more_arch` extends the list of target architectures in
  `libFDK/include/FDK_archdef.h`, which upstream keeps minimal.
- `DEB_LDFLAGS_MAINT_APPEND = -Wl,--no-undefined`: the shared library must not
  contain unresolved symbols.
- The library version carries the `+crick` suffix, so `pipewire` built here can
  depend on exactly this build: `libfdk-aac-dev` requires
  `libfdk-aac2t64 (= 2.0.3-1+crick)`.
- Debug symbol packages (`-dbgsym`) are not built and not published.
