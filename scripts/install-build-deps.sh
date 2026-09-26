#!/usr/bin/env bash
set -euo pipefail

# install-build-deps.sh: parse Build-Depends of a package from its debian/
# control and install them explicitly with apt-get.
#
# Replaces `mk-build-deps --install --remove` (equivs), which failed in CI
# without any visible apt diagnostics. Differences:
#   - architecture restrictions ([amd64], [linux-any], ...) and build-profile
#     restrictions (<!nodoc>, ...) are evaluated for the current build;
#   - version constraints are not passed to apt (they are validated against
#     the distro separately); only package names are installed;
#   - packages already installed locally (Stage-1 artifacts such as
#     libwlroots-0.20-dev, libtsm-dev, libfdk-aac-dev) are skipped even when
#     they are not present in the archive;
#   - alternatives "a | b" resolve to the first available candidate;
#   - unresolvable entries abort the build with an explicit error.
#
# Usage: ./install-build-deps.sh <package-name>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PACKAGE="${1:-}"
if [[ -z "$PACKAGE" ]]; then
  echo "Usage: $0 <package-name>"
  exit 1
fi

CONTROL="$REPO_ROOT/packages/$PACKAGE/debian/control"
if [[ ! -f "$CONTROL" ]]; then
  echo "Error: control file not found: $CONTROL" >&2
  exit 1
fi

# One entry per Build-Depends item; alternatives are kept as "a | b".
# Restricted entries that do not apply to this build are dropped.
PARSED="$(DEB_BUILD_PROFILES="${DEB_BUILD_PROFILES:-}" python3 - "$CONTROL" <<'PYEOF'
import os
import re
import sys

path = sys.argv[1]
profiles = set(os.environ.get("DEB_BUILD_PROFILES", "").split())

with open(path, encoding="utf-8") as fh:
    lines = fh.read().splitlines()

# First stanza only (the source package).
stanza = []
for line in lines:
    if not line.strip():
        break
    stanza.append(line)

blob, field = [], None
for line in stanza:
    m = re.match(r"^(Build-Depends(?:-Arch|-Indep)?):\s*(.*)$", line)
    if m:
        field = m.group(1)
        blob.append(m.group(2))
        continue
    if field is not None and line[:1] in (" ", "\t"):
        blob.append(line.strip())
    elif line and line[:1] not in (" ", "\t"):
        field = None

text = " ".join(blob)

for item in text.split(","):
    item = item.strip()
    if not item:
        continue

    # Strip build-profile (<a b> / <!a b>) and architecture ([amd64 !i386])
    # restrictions, dropping the entry when it does not apply to this build.
    drop = False
    while True:
        m = re.search(r"<([^>]*)>\s*$", item)
        if m:
            specs = m.group(1).split()
            pos = {s for s in specs if not s.startswith("!")}
            neg = {s[1:] for s in specs if s.startswith("!")}
            if pos and not (profiles & pos):
                drop = True
                break
            if profiles & neg:
                drop = True
                break
            item = item[: m.start()].strip()
            continue

        m = re.search(r"\[([^\]]*)\]", item)
        if m:
            specs = m.group(1).split()
            neg = {s[1:] for s in specs if s.startswith("!")}
            pos = {s for s in specs if not s.startswith("!")}
            # Positive list: must cover amd64 (directly, via "any" or linux-any).
            arch_ok = True
            if pos:
                arch_ok = bool(pos & {"amd64", "any", "linux-any", "linux-all"})
            if "amd64" in neg or "any" in neg:
                arch_ok = False
            if not arch_ok:
                drop = True
                break
            item = re.sub(r"\s*\[[^\]]*\]", "", item).strip()
            continue

        break

    if drop:
        continue

    # Version constraints are not passed to apt.
    item = re.sub(r"\([^)]*\)", "", item).strip()
    item = item.replace(":any", "").replace(":native", "").strip()
    if item:
        print(item)
PYEOF
)" || {
  echo "Error: failed to parse Build-Depends from $CONTROL" >&2
  exit 1
}

if [[ -n "$PARSED" ]]; then
  mapfile -t DEPS <<< "$PARSED"
else
  DEPS=()
fi

if [[ ${#DEPS[@]} -eq 0 ]]; then
  echo "No build dependencies found in $CONTROL"
  exit 0
fi

# Does apt know this name (real package, archive virtual, or unique provider)?
apt_resolvable() {
  local name="$1"
  apt-cache policy "$name" 2>/dev/null | grep -qE 'Candidate: [0-9]' && return 0
  apt-get install -s -y --no-install-recommends "$name" >/dev/null 2>&1
}

is_installed() {
  local name="$1"
  dpkg-query -W -f='${Status}' "$name" 2>/dev/null | grep -q '^install ok installed$'
}

TO_INSTALL=()
for entry in "${DEPS[@]}"; do
  IFS='|' read -r -a alts <<< "$entry"
  resolved=""
  for alt in "${alts[@]}"; do
    alt="$(echo "$alt" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -z "$alt" ]] && continue
    if is_installed "$alt"; then
      resolved="$alt (already installed)"
      break
    fi
    if apt_resolvable "$alt"; then
      resolved="$alt"
      break
    fi
  done
  if [[ -z "$resolved" ]]; then
    echo "Error: cannot resolve build-dependency '$entry' for $PACKAGE" >&2
    echo "       (not installed and no candidate in the configured apt sources)" >&2
    exit 1
  fi
  if [[ "$resolved" == *"already installed"* ]]; then
    echo "==> skipping $entry: $resolved"
    continue
  fi
  TO_INSTALL+=("$resolved")
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
  echo "==> Installing ${#TO_INSTALL[@]} build dependenc(ies) for $PACKAGE:"
  printf '    %s\n' "${TO_INSTALL[@]}"
  apt-get install -y --no-install-recommends "${TO_INSTALL[@]}"
else
  echo "==> All build dependencies for $PACKAGE are already installed"
fi

echo "SUCCESS: build dependencies installed for $PACKAGE"
