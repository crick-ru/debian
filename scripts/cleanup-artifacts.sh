#!/usr/bin/env bash
set -euo pipefail

# cleanup-artifacts.sh [max-age-hours]
#
# Deletes CI artifacts older than max-age-hours (default 12) to keep the storage
# quota of a free GitHub account small: public accounts share 0.5 GB between
# artifacts of all repositories. The current workflow run is never touched, so a
# deploy can still read the artifacts it uploaded.
#
# Requires: GITHUB_REPOSITORY, GH_TOKEN (or GITHUB_TOKEN) with actions:read,
#           curl-free (python3 does the HTTP), no extra packages.
# DRY_RUN=1 prints what would be deleted without deleting anything.

MAX_AGE_HOURS="${1:-12}"

python3 - "$MAX_AGE_HOURS" <<'PYEOF'
import json
import os
import sys
import urllib.request
from datetime import datetime, timezone

repo = os.environ.get("GITHUB_REPOSITORY", "")
token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN", "")
max_age_hours = float(sys.argv[1])
dry_run = os.environ.get("DRY_RUN", "0") == "1"
current_run = os.environ.get("GITHUB_RUN_ID", "")

if not repo or not token:
    sys.exit("GITHUB_REPOSITORY and GH_TOKEN/GITHUB_TOKEN are required")

api = f"https://api.github.com/repos/{repo}/actions/artifacts"
headers = {
    "Authorization": f"Bearer {token}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
}


def request(url, method="GET"):
    req = urllib.request.Request(url, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=60) as response:
        body = response.read()
        return json.loads(body) if body else {}


cutoff = datetime.now(timezone.utc).timestamp() - max_age_hours * 3600
stale = []
kept = 0
page = 1
while True:
    data = request(f"{api}?per_page=100&page={page}")
    artifacts = data.get("artifacts", [])
    if not artifacts:
        break
    for artifact in artifacts:
        if str(artifact.get("workflow_run", {}).get("id", "")) == current_run:
            kept += 1
            continue
        created = datetime.fromisoformat(
            artifact["created_at"].replace("Z", "+00:00")
        ).timestamp()
        if created < cutoff:
            stale.append((artifact["id"], artifact["name"], artifact["created_at"]))
        else:
            kept += 1
    if len(artifacts) < 100:
        break
    page += 1

print(f"==> Artifacts: {kept} kept, {len(stale)} older than {max_age_hours} h")
for artifact_id, name, created in stale:
    if dry_run:
        print(f"    would delete #{artifact_id} {name} ({created})")
        continue
    request(f"{api}/{artifact_id}", method="DELETE")
    print(f"    deleted #{artifact_id} {name} ({created})")
PYEOF
