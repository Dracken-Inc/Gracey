#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: env file not found: $ENV_FILE"
  exit 1
fi

required_vars=(
  GRACEY_NODE_HOSTNAME
  API_GATEWAY_AUTH_TOKEN
  TELEGRAM_BOT_TOKEN
  INFERENCE_ROUTER_URL
)

placeholder_markers=(
  "<set-"
  "<optional"
  "changeme"
  "replace_me"
)

missing=0
for var in "${required_vars[@]}"; do
  if ! grep -qE "^${var}=" "$ENV_FILE"; then
    echo "ERROR: missing required variable: $var"
    missing=1
  fi
done

while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  key="${line%%=*}"
  value="${line#*=}"

  for marker in "${placeholder_markers[@]}"; do
    if [[ "$value" == *"$marker"* ]]; then
      echo "ERROR: variable $key contains placeholder value: $value"
      missing=1
    fi
  done

done < "$ENV_FILE"

if [[ "$missing" -ne 0 ]]; then
  echo "Validation failed for $ENV_FILE"
  exit 2
fi

echo "Environment file validation passed: $ENV_FILE"
