#!/usr/bin/env bash
set -euo pipefail

# generate-repo.sh: Generate the APT repository layout (dists/, pool/), sign the
# metadata and drop an HTML listing into every directory of the published tree.
#
# Target: debian trixie, arch amd64, single component "backports".
# Signing: the key imported by the publish job (GPG_PRIVATE_KEY), its passphrase
# in GPG_PASSPHRASE. The public key is exported as crick-backports.gpg, so
# clients can pin it via Signed-By.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DIST_DIR="$REPO_ROOT/dist"
POOL_DIR="$DIST_DIR/pool"
DISTS_DIR="$DIST_DIR/dists/trixie"

ARCH="amd64"
COMPONENT="backports"
REPO_NAME="crick Debian backports"
PUBLIC_KEY_NAME="crick-backports.gpg"

mkdir -p "$DIST_DIR"
mkdir -p "$POOL_DIR/$COMPONENT"

# All built packages go into the single component pool.
if [[ -d "$REPO_ROOT/repo-pool" ]]; then
  shopt -s nullglob
  for deb in "$REPO_ROOT/repo-pool"/*.deb; do
    cp -u "$deb" "$POOL_DIR/$COMPONENT/"
  done
  shopt -u nullglob
fi

# Package indexes for the single component
BIN_DIR="$DISTS_DIR/$COMPONENT/binary-$ARCH"
mkdir -p "$BIN_DIR"

echo "==> Scanning packages for $COMPONENT binary-$ARCH..."
cd "$DIST_DIR"
if ls -1 "pool/$COMPONENT"/*.deb 1>/dev/null 2>&1; then
  dpkg-scanpackages -m "pool/$COMPONENT" /dev/null > "$BIN_DIR/Packages"
else
  touch "$BIN_DIR/Packages"
fi

gzip -9c "$BIN_DIR/Packages" > "$BIN_DIR/Packages.gz"
xz -c "$BIN_DIR/Packages" > "$BIN_DIR/Packages.xz"

# Generate Release file
echo "==> Generating Release file for trixie..."
cd "$DISTS_DIR"

RELEASE_DATE="$(LC_ALL=C date -Ru)"
VALID_UNTIL="$(LC_ALL=C date -Ru -d '+7 days')"

cat << EOF_REL > Release
Origin: $REPO_NAME
Label: crick-backports
Suite: trixie
Codename: trixie
Architectures: $ARCH
Components: $COMPONENT
Description: Backports for Debian trixie (amd64)
EOF_REL

echo "Date: $RELEASE_DATE" >> Release
echo "Valid-Until: $VALID_UNTIL" >> Release
echo "MD5Sum:" >> Release

generate_hashes() {
  local cmd="$1"
  for f in "$COMPONENT/binary-$ARCH"/Packages*; do
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

# Signing. The key is imported by the publish job; its passphrase arrives in
# GPG_PASSPHRASE. Loopback pinentry is required for a non-interactive runner.
SIGN_ARGS=(--batch --yes --pinentry-mode loopback)
if [[ -n "${GPG_PASSPHRASE:-}" ]]; then
  SIGN_ARGS+=(--passphrase "$GPG_PASSPHRASE")
fi

have_key=false
if gpg --list-secret-keys 2>/dev/null | grep -q "sec"; then
  have_key=true
fi

if [[ "$have_key" == true ]]; then
  echo "==> Signing Release file..."
  rm -f InRelease Release.gpg
  gpg "${SIGN_ARGS[@]}" --clearsign -o InRelease Release
  gpg "${SIGN_ARGS[@]}" --armor --detach-sign -o Release.gpg Release
  echo "Release signed successfully."
else
  echo "Notice: GPG signing key not found; skipping repository signature."
fi

# Export the public key next to the metadata (binary keyring for Signed-By).
if [[ "$have_key" == true ]]; then
  KEY_ID="$(gpg --list-secret-keys --with-colons | awk -F: '/^sec/ {print $5; exit}')"
  if [[ -n "$KEY_ID" ]]; then
    rm -f "$DIST_DIR/$PUBLIC_KEY_NAME"
    gpg --batch --yes --export "$KEY_ID" > "$DIST_DIR/$PUBLIC_KEY_NAME"
    chmod 0644 "$DIST_DIR/$PUBLIC_KEY_NAME"
    echo "Exported public key: $PUBLIC_KEY_NAME (fingerprint $(gpg --with-colons --fingerprint "$KEY_ID" | awk -F: '/^fpr:/ {print $10; exit}'))"
  fi
fi

# Laconic HTML listing in every directory of the published tree, so that
# browsing https://crick-ru.github.io/debian/ and its subdirectories works
# instead of returning 404.
generate_indexes() {
  local root="$1"
  local dir rel name type size date human depth parent out i
  echo "==> Generating HTML directory listings..."
  cd "$root"
  while IFS= read -r -d '' dir; do
    rel="${dir#.}"; rel="${rel:-/}"
    out="${dir#./}"
    out="${out%/}/index.html"

    # ".." repeated for every path component above the current one
    depth="${rel//[^\/]/}"
    parent=""
    for ((i = 0; i < ${#depth}; i++)); do
      parent="../$parent"
    done

    {
      echo '<!DOCTYPE html>'
      echo '<html lang="en"><head><meta charset="utf-8">'
      echo "<title>${REPO_NAME}${rel}</title>"
      echo '<style>body{font:14px/1.5 system-ui,sans-serif;margin:2rem auto;max-width:64rem;padding:0 1rem;color:#222}'
      echo 'a{text-decoration:none}a:hover{text-decoration:underline}table{border-collapse:collapse;width:100%}'
      echo 'td{padding:.2rem .5rem;border-bottom:1px solid #eee}td.r{text-align:right;color:#888;white-space:nowrap}</style>'
      echo '</head><body>'
      echo "<h1>${REPO_NAME}</h1>"
      if [[ "$rel" == "/" ]]; then
        echo '<p>Backports for Debian 13 (trixie), amd64.</p>'
      else
        echo "<p><a href=\"${parent}\">${parent}</a>${rel}</p>"
      fi
      echo '<table>'
      while IFS=$'\t' read -r type name size date; do
        [[ "$name" == "index.html" ]] && continue
        human="$(LC_ALL=C awk -v b="$size" 'BEGIN { split("B KiB MiB GiB", u, " "); i = 1; while (b >= 1024 && i < 4) { b /= 1024; i++ } printf (i == 1 ? "%d %s" : "%.1f %s"), b, u[i] }')"
        if [[ "$type" == "d" ]]; then
          printf '<tr><td><a href="%s/">%s/</a></td><td class="r"></td><td class="r">%s</td></tr>\n' "$name" "$name" "$date"
        else
          printf '<tr><td><a href="%s">%s</a></td><td class="r">%s</td><td class="r">%s</td></tr>\n' "$name" "$name" "$human" "$date"
        fi
      done < <(find "$dir" -mindepth 1 -maxdepth 1 -printf '%y\t%f\t%s\t%TY-%Tm-%Td %TH:%TM\n' | LC_ALL=C sort -t"$(printf '\t')" -k1,1 -k2,2)
      echo '</table>'
      echo '</body></html>'
    } > "$out"
  done < <(find . -type d -print0 | LC_ALL=C sort -z)
}

generate_indexes "$DIST_DIR"

echo "SUCCESS: APT repository generated in $DIST_DIR"
