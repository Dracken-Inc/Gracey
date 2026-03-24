#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8080}"

echo "Starting Gracey API in mock mode on port ${PORT}"
cd "$(dirname "$0")/../interfaces/api"

if [ ! -d .venv ]; then
  python3 -m venv .venv
fi

.venv/bin/python -m pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
.venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port "${PORT}" --reload
