#!/usr/bin/env bash
set -euo pipefail

# pkg-version.sh: print the Debian version used for builds of a package
#   [<epoch>:]<upstream version>-<revision>+crick
# The upstream version comes from fetch-upstream.sh, the revision and the epoch
# too, so the version table lives in exactly one place; the build script and the
# CI cache keys both call this. The epoch is empty for every package but ffmpeg:
# it carries epoch 7 for historical reasons, and without it our 9.0.2 build would
# be older than the trixie 7:7.1.5 and apt would never pick it up.
# Usage: ./pkg-version.sh <package-name>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE="${1:-}"
if [[ -z "$PACKAGE" ]]; then
  echo "Usage: $0 <package-name>" >&2
  exit 1
fi

if ! upstream_version="$("$SCRIPT_DIR/fetch-upstream.sh" --print-version "$PACKAGE")"; then
  echo "Error: cannot determine the version of $PACKAGE" >&2
  exit 1
fi
if ! revision="$("$SCRIPT_DIR/fetch-upstream.sh" --print-revision "$PACKAGE")"; then
  echo "Error: cannot determine the revision of $PACKAGE" >&2
  exit 1
fi
if ! epoch="$("$SCRIPT_DIR/fetch-upstream.sh" --print-epoch "$PACKAGE")"; then
  echo "Error: cannot determine the epoch of $PACKAGE" >&2
  exit 1
fi
if [[ -n "$epoch" ]]; then
  epoch="${epoch}:"
fi
echo "${epoch}${upstream_version}-${revision}+crick"