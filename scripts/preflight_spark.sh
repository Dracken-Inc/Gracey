#!/usr/bin/env bash
set -euo pipefail

TARGET_HOSTNAME="${1:-promaxgb10-4afb.local}"

check_cmd() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "PASS: $name"
  else
    echo "FAIL: $name"
    return 1
  fi
}

failed=0

echo "== Gracey Spark Preflight =="
echo "Target hostname: $TARGET_HOSTNAME"

if hostname | grep -qi "${TARGET_HOSTNAME%%.*}"; then
  echo "PASS: hostname matches node"
else
  echo "WARN: hostname does not match expected target"
fi

check_cmd "nvidia-smi" "nvidia-smi" || failed=1
check_cmd "docker" "docker --version" || failed=1
check_cmd "python3" "python3 --version" || failed=1
check_cmd "tailscale" "tailscale status" || failed=1
check_cmd "nemoclaw" "command -v nemoclaw" || failed=1
check_cmd "openshell" "command -v openshell" || failed=1

if [[ "$failed" -ne 0 ]]; then
  echo "Preflight completed with failures"
  exit 2
fi

echo "Preflight passed"
