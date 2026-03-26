#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${1:-/opt/gracey}"
ENV_FILE="$INSTALL_DIR/.env"
API_DIR="$INSTALL_DIR/interfaces/api"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: missing env file: $ENV_FILE"
  exit 1
fi

if [[ ! -d "$API_DIR" ]]; then
  echo "ERROR: missing API directory: $API_DIR"
  exit 1
fi

bash "$INSTALL_DIR/scripts/validate_env.sh" "$ENV_FILE"

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

if [[ ! -d "$API_DIR/.venv" ]]; then
  python3 -m venv "$API_DIR/.venv"
fi

"$API_DIR/.venv/bin/python" -m pip install --upgrade pip >/dev/null
"$API_DIR/.venv/bin/pip" install -r "$API_DIR/requirements.txt" >/dev/null

HOST="${GRACEY_API_HOST:-0.0.0.0}"
PORT="${GRACEY_API_PORT:-8080}"

cd "$API_DIR"
exec "$API_DIR/.venv/bin/python" -m uvicorn app.main:app --host "$HOST" --port "$PORT"
