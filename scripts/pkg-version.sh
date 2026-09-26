#!/usr/bin/env bash
set -euo pipefail

# pkg-version.sh: print the Debian version used for builds of a package
#   <upstream version>-1+crick
# The upstream version comes from fetch-upstream.sh, so the version table lives
# in exactly one place; the build script and the CI cache keys both call this.
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
echo "${upstream_version}-1+crick"