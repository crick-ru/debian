#!/usr/bin/env bash
set -euo pipefail

# cleanup-artifacts.sh [keep-previous-runs] [max-age-hours]
#
# A free GitHub account shares 0.5 GB between the artifacts of all its
# repositories, while the Actions cache (10 GB per repository) is used for the
# reusable build results. Therefore only the artifacts that are still needed
# are kept:
#
#   * the current workflow run (the publish job reads them),
#   * the N most recent previous runs (default 1) for debugging,
#   * any run that has not finished yet.
#
# Everything else is deleted. DRY_RUN=1 lists what would be deleted.

KEEP_PREVIOUS="${1:-1}"
MAX_AGE_HOURS="${2:-24}"

python3 - "$KEEP_PREVIOUS" "$MAX_AGE_HOURS" <<'PYEOF'
import json
import os
import sys
import urllib.request
from datetime import datetime, timezone

repo = os.environ.get("GITHUB_REPOSITORY", "")
token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN", "")
keep_previous = int(sys.argv[1])
max_age_hours = float(sys.argv[2])
dry_run = os.environ.get("DRY_RUN", "0") == "1"
current_run = os.environ.get("GITHUB_RUN_ID", "")

if not repo or not token:
    sys.exit("GITHUB_REPOSITORY and GH_TOKEN/GITHUB_TOKEN are required")

api = f"https://api.github.com/repos/{repo}/actions"
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


artifacts = []
page = 1
while True:
    data = request(f"{api}/artifacts?per_page=100&page={page}")
    batch = data.get("artifacts", [])
    if not batch:
        break
    artifacts.extend(batch)
    if len(batch) < 100:
        break
    page += 1

# Runs that still have to finish keep their artifacts.
run_status = {}


def is_running(run_id):
    if run_id not in run_status:
        try:
            run_status[run_id] = request(f"{api}/runs/{run_id}").get("status", "")
        except Exception:
            run_status[run_id] = "unknown"
    return run_status[run_id] != "completed"


cutoff = datetime.now(timezone.utc).timestamp() - max_age_hours * 3600

# Most recent previous runs (by the newest artifact they produced).
run_newest = {}
for artifact in artifacts:
    run_id = str(artifact.get("workflow_run", {}).get("id", ""))
    created = datetime.fromisoformat(
        artifact["created_at"].replace("Z", "+00:00")
    ).timestamp()
    if run_id and (run_id not in run_newest or created > run_newest[run_id]):
        run_newest[run_id] = created
other_runs = [r for r in run_newest if r != current_run]
other_runs.sort(key=lambda r: run_newest[r], reverse=True)
keep_runs = set(other_runs[:keep_previous])
if current_run:
    keep_runs.add(current_run)

stale, kept = [], 0
for artifact in artifacts:
    run_id = str(artifact.get("workflow_run", {}).get("id", ""))
    created = datetime.fromisoformat(
        artifact["created_at"].replace("Z", "+00:00")
    ).timestamp()
    if run_id in keep_runs and created >= cutoff:
        kept += 1
        continue
    if run_id != current_run and is_running(run_id):
        kept += 1
        continue
    stale.append((artifact["id"], artifact["name"], artifact["created_at"]))

print(f"==> Artifacts: {kept} kept, {len(stale)} to delete "
      f"(runs kept: current + {keep_previous} previous)")
for artifact_id, name, created in stale:
    if dry_run:
        print(f"    would delete #{artifact_id} {name} ({created})")
        continue
    try:
        request(f"{api}/artifacts/{artifact_id}", method="DELETE")
        print(f"    deleted #{artifact_id} {name}")
    except Exception as error:  # keep going, this is housekeeping
        print(f"    failed to delete #{artifact_id} {name}: {error}")
PYEOF

