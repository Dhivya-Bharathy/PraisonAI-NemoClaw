#!/usr/bin/env bash
# If openshell sandbox create did not stream workload stdout into run.log, pull
# artifact files from the stopped container and print ===BEGIN/END=== markers.
set -euo pipefail

DEMO_NAME="${1:?usage: append-artifacts-from-container.sh <sandbox-name>}"
DEMO_NAME="$(printf '%s' "$DEMO_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"

cid=""
for _ in $(seq 1 600); do
  cid="$(docker ps -a --filter "name=openshell-default--${DEMO_NAME}-" --format '{{.ID}}' | head -1 || true)"
  if [ -n "$cid" ]; then
    status="$(docker inspect -f '{{.State.Status}}' "$cid")"
    if [ "$status" = "exited" ]; then
      break
    fi
  fi
  sleep 2
done

if [ -z "${cid:-}" ]; then
  echo "append-artifacts: no container for sandbox ${DEMO_NAME}" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
docker cp "${cid}:/sandbox/work/." "$tmpdir/" 2>/dev/null || true

for f in probe.json metrics.json risk_report.md audit.jsonl praisonai.log hosts.sha256.before hosts.sha256.after; do
  if [ -f "$tmpdir/$f" ]; then
    printf '\n===BEGIN %s===\n' "$f"
    cat "$tmpdir/$f"
    printf '\n===END %s===\n' "$f"
  fi
done

exit_code="$(docker inspect -f '{{.State.ExitCode}}' "$cid")"
printf '\n===EXIT %s===\n' "$exit_code"
