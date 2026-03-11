#!/usr/bin/env bash
# run_openclaw.sh
# Starts the OpenClaw inference worker with GB10-optimized flags.
# Run after installing via infrastructure/openclaw_install.sh.

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
GRACEY_HOME="${GRACEY_HOME:-/opt/gracey}"
GRACEY_VENV="${GRACEY_VENV:-$HOME/gracey-env}"
OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$GRACEY_HOME/openclaw/openclaw_config.yaml}"
OPENCLAW_LOG_DIR="${GRACEY_LOGS_DIR:-/var/log/gracey}"
OPENCLAW_PID_FILE="/tmp/openclaw.pid"

# ── Helpers ───────────────────────────────────────────────────────────────────
log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ── Preflight ─────────────────────────────────────────────────────────────────
if [ ! -f "$OPENCLAW_CONFIG" ]; then
    echo "ERROR: Config file not found: $OPENCLAW_CONFIG"
    echo "       Copy openclaw/openclaw_config.yaml to $OPENCLAW_CONFIG and edit it."
    exit 1
fi

if [ ! -d "$GRACEY_VENV" ]; then
    echo "ERROR: Virtual environment not found: $GRACEY_VENV"
    echo "       Run infrastructure/openclaw_install.sh first."
    exit 1
fi

# shellcheck source=/dev/null
source "$GRACEY_VENV/bin/activate"

command -v openclaw >/dev/null 2>&1 || {
    echo "ERROR: 'openclaw' executable not found in PATH."
    echo "       Run infrastructure/openclaw_install.sh first."
    exit 1
}

# ── GB10-Specific Environment Tuning ─────────────────────────────────────────
# Unified memory: allow expandable segments to avoid OOM on large allocations
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Use all available CUDA cores on the single GB10 chip
export CUDA_VISIBLE_DEVICES=0

# Maximize NVLink bandwidth utilisation
export CUDA_DEVICE_MAX_CONNECTIONS=4

# Disable tokeniser parallelism warnings when using multiple workers
export TOKENIZERS_PARALLELISM=false

# Flash Attention 3 (Blackwell) — enable via environment if not set in config
export FLASH_ATTENTION_FORCE_BUILD=TRUE

# ── Logging Setup ─────────────────────────────────────────────────────────────
mkdir -p "$OPENCLAW_LOG_DIR"
LOGFILE="$OPENCLAW_LOG_DIR/openclaw_$(date +%Y%m%d).log"
log "Starting OpenClaw ..."
log "Config : $OPENCLAW_CONFIG"
log "Log    : $LOGFILE"

# ── Start OpenClaw ────────────────────────────────────────────────────────────
# The openclaw serve command is the standard entrypoint.
# Flags mirror the openclaw_config.yaml but can override via CLI for quick tests.
exec openclaw serve \
    --config "$OPENCLAW_CONFIG" \
    --log-level INFO \
    2>&1 | tee -a "$LOGFILE" &

OPENCLAW_PID=$!
echo "$OPENCLAW_PID" > "$OPENCLAW_PID_FILE"
log "OpenClaw started (PID $OPENCLAW_PID). PID file: $OPENCLAW_PID_FILE"
log "To stop: kill \$(cat $OPENCLAW_PID_FILE)"

# ── Wait and Monitor ──────────────────────────────────────────────────────────
# Give the worker time to load the model before declaring success
STARTUP_TIMEOUT="${OPENCLAW_STARTUP_TIMEOUT:-120}"
log "Waiting up to ${STARTUP_TIMEOUT}s for OpenClaw to become ready ..."

for i in $(seq 1 "$STARTUP_TIMEOUT"); do
    if curl -sf http://127.0.0.1:9000/healthz >/dev/null 2>&1; then
        log "OpenClaw is ready after ${i}s."
        break
    fi
    if ! kill -0 "$OPENCLAW_PID" 2>/dev/null; then
        log "ERROR: OpenClaw process exited unexpectedly. Check $LOGFILE"
        exit 1
    fi
    sleep 1
done

log "=== OpenClaw is running. To follow logs: tail -f $LOGFILE"
wait "$OPENCLAW_PID"
