#!/usr/bin/env bash
# Host side: create the provider + route, build the image, run the team in an
# OpenShell sandbox and capture the log to out/run.log for verify.sh.
# Requires: docker, openshell (pinned, see README), NVIDIA_API_KEY.
# Use a DEDICATED gateway: `openshell inference set` changes the route for every
# sandbox on the gateway.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Do not use env var NAME — many shells set NAME=HOSTNAME (invalid for OpenShell names).
DEMO_NAME="${PRAISONAI_DEMO_NAME:-praisonai-demo}"
DEMO_NAME="$(printf '%s' "$DEMO_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"
IMAGE="${IMAGE:-praisonai-contract-review:dev}"
MODEL="${MODEL:-nvidia/nemotron-3.5-lightning-30b-a3b}"
OPENSHELL_VERSION="${OPENSHELL_VERSION:-0.0.116}"

: "${NVIDIA_API_KEY:?Set NVIDIA_API_KEY}"
if ! openshell --version 2>/dev/null | grep -q "$OPENSHELL_VERSION"; then
  echo "warning: expected OpenShell $OPENSHELL_VERSION, got: $(openshell --version 2>&1 || echo none)" >&2
  echo "         OpenShell 0.1.0 removed 'openshell inference' and inference.local." >&2
fi

openshell provider delete "$DEMO_NAME" 2>/dev/null || true
openshell sandbox delete "$DEMO_NAME" 2>/dev/null || true
openshell provider create --name "$DEMO_NAME" --type nvidia --credential NVIDIA_API_KEY
openshell inference set --provider "$DEMO_NAME" --model "$MODEL"
docker build -t "$IMAGE" "$HERE"

mkdir -p "$HERE/out"
chmod +x "$HERE/scripts/append-artifacts-from-container.sh" 2>/dev/null || true
# --no-tty: when stdout is piped to tee, a PTY prevents streaming workload output.
set +e
openshell sandbox create --no-tty --from "$IMAGE" --name "$DEMO_NAME" --policy "$HERE/policy.yaml" \
  -- bash /app/scripts/run.sh 2>&1 | tee "$HERE/out/run.log"
rc=${PIPESTATUS[0]}
set -e
if ! grep -q '===BEGIN probe.json===' "$HERE/out/run.log" 2>/dev/null; then
  echo "run.log missing artifact markers; appending from container filesystem..." >&2
  "$HERE/scripts/append-artifacts-from-container.sh" "$DEMO_NAME" >>"$HERE/out/run.log"
fi
echo "sandbox run exited with $rc; now run scripts/verify.sh"
exit "$rc"
