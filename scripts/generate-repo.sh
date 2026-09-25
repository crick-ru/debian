#!/usr/bin/env bash
set -euo pipefail

# generate-repo.sh: Generate APT repository layout (dists/, pool/) and sign metadata
# Target distro: debian, release: trixie, arch: amd64, components: main non-free

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DIST_DIR="$REPO_ROOT/dist"
POOL_DIR="$DIST_DIR/pool"
DISTS_DIR="$DIST_DIR/dists/trixie"

ARCH="amd64"
COMPONENTS=("main" "non-free")

mkdir -p "$DIST_DIR"
mkdir -p "$POOL_DIR/main"
mkdir -p "$POOL_DIR/non-free"

# If packages were built into repo-pool/, sort them into proper component pools
if [[ -d "$REPO_ROOT/repo-pool" ]]; then
  for deb in "$REPO_ROOT/repo-pool"/*.deb; do
    [[ -f "$deb" ]] || continue
    debname="$(basename "$deb")"
    if [[ "$debname" =~ fdk-aac || "$debname" =~ pipewire ]]; then
      cp -u "$deb" "$POOL_DIR/non-free/"
    else
      cp -u "$deb" "$POOL_DIR/main/"
    fi
  done
fi

for comp in "${COMPONENTS[@]}"; do
  BIN_DIR="$DISTS_DIR/$comp/binary-$ARCH"
  mkdir -p "$BIN_DIR"

  echo "==> Scanning packages for $comp binary-$ARCH..."
  cd "$DIST_DIR"
  if ls -1 "pool/$comp"/*.deb 1>/dev/null 2>&1; then
    dpkg-scanpackages -m "pool/$comp" /dev/null > "$BIN_DIR/Packages"
  else
    touch "$BIN_DIR/Packages"
  fi

  gzip -9c "$BIN_DIR/Packages" > "$BIN_DIR/Packages.gz"
  xz -c "$BIN_DIR/Packages" > "$BIN_DIR/Packages.xz"
done

# Generate Release file
echo "==> Generating Release file for trixie..."
cd "$DISTS_DIR"

RELEASE_DATE="$(LC_ALL=C date -Ru)"
VALID_UNTIL="$(LC_ALL=C date -Ru -d '+7 days')"

cat << 'EOF_REL' > Release
Origin: crick Debian Repository
Label: crick
Suite: trixie
Codename: trixie
Architectures: amd64
Components: main non-free
Description: Debian Trixie Wayland-Only / Modern Packages Repository
EOF_REL

echo "Date: $RELEASE_DATE" >> Release
echo "Valid-Until: $VALID_UNTIL" >> Release
echo "MD5Sum:" >> Release

generate_hashes() {
  local cmd="$1"
  for f in main/binary-$ARCH/Packages* non-free/binary-$ARCH/Packages*; do
    if [[ -f "$f" ]]; then
      size=$(wc -c < "$f")
      hash="$($cmd "$f" | cut -d' ' -f1)"
      printf " %s %16d %s\n" "$hash" "$size" "$f"
    fi
  done
}

generate_hashes "md5sum" >> Release
echo "SHA256:" >> Release
generate_hashes "sha256sum" >> Release

# Sign Release if GPG key is present
if [[ -n "${GPG_PRIVATE_KEY:-}" ]] || gpg --list-secret-keys 2>/dev/null | grep -q "sec"; then
  echo "==> Signing Release file..."
  rm -f InRelease Release.gpg
  gpg --batch --yes --clearsign -o InRelease Release
  gpg --batch --yes -abs -o Release.gpg Release
  echo "Release signed successfully."
else
  echo "Notice: GPG signing key not found; skipping repository signature."
fi

# Export public GPG key if available
if gpg --list-secret-keys 2>/dev/null | grep -q "sec"; then
  KEY_ID=$(gpg --list-secret-keys --with-colons | grep '^sec' | head -n1 | cut -d: -f5)
  if [[ -n "$KEY_ID" ]]; then
    gpg --armor --export "$KEY_ID" > "$DIST_DIR/public.gpg.key"
    gpg --export "$KEY_ID" > "$DIST_DIR/repo.gpg"
  fi
fi

echo "SUCCESS: APT repository generated in $DIST_DIR"
