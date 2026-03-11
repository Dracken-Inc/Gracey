#!/usr/bin/env bash
# openclaw_install.sh
# Installs OpenClaw and all required Python packages on a Gracey-GB10 node.
# Run after completing setup_gb10_environment.md.

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
GRACEY_HOME="${GRACEY_HOME:-/opt/gracey}"
GRACEY_VENV="${GRACEY_VENV:-$HOME/gracey-env}"
PYTHON="${PYTHON:-python3}"
CUDA_VERSION="${CUDA_VERSION:-12.6}"
OPENCLAW_REPO="https://github.com/openclaw/openclaw.git"
OPENCLAW_REF="${OPENCLAW_REF:-main}"
LOG_FILE="/tmp/openclaw_install_$(date +%Y%m%d_%H%M%S).log"

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
fail() { log "ERROR: $*"; exit 1; }

# ── Preflight checks ─────────────────────────────────────────────────────────
log "=== Gracey-GB10 OpenClaw Installer ==="
log "Log: $LOG_FILE"

command -v "$PYTHON" >/dev/null 2>&1 || fail "Python3 not found. Run setup_gb10_environment.md first."
command -v nvcc      >/dev/null 2>&1 || fail "nvcc not found. CUDA is not installed or not in PATH."
command -v git       >/dev/null 2>&1 || fail "git not found."

log "Python: $($PYTHON --version)"
log "CUDA: $(nvcc --version | grep 'release' | awk '{print $5}' | tr -d ',')"

# ── Virtual environment ───────────────────────────────────────────────────────
if [ ! -d "$GRACEY_VENV" ]; then
    log "Creating virtual environment at $GRACEY_VENV ..."
    "$PYTHON" -m venv "$GRACEY_VENV"
fi

# shellcheck source=/dev/null
source "$GRACEY_VENV/bin/activate"
log "Virtual environment activated: $GRACEY_VENV"

pip install --upgrade pip setuptools wheel >> "$LOG_FILE" 2>&1

# ── PyTorch (CUDA-enabled) ────────────────────────────────────────────────────
log "Installing PyTorch with CUDA ${CUDA_VERSION} support ..."
CUDA_TAG="cu$(echo "$CUDA_VERSION" | tr -d '.')"  # e.g. cu126
pip install torch torchvision torchaudio \
    --index-url "https://download.pytorch.org/whl/${CUDA_TAG}" >> "$LOG_FILE" 2>&1

# ── Core Python dependencies ──────────────────────────────────────────────────
log "Installing core dependencies ..."
pip install \
    accelerate \
    transformers \
    bitsandbytes \
    sentencepiece \
    tiktoken \
    einops \
    safetensors \
    pyyaml \
    python-dotenv \
    fastapi \
    uvicorn[standard] \
    httpx \
    aiohttp \
    pydantic \
    loguru \
    rich \
    >> "$LOG_FILE" 2>&1

# ── Telegram bot library ──────────────────────────────────────────────────────
log "Installing Telegram bot library ..."
pip install python-telegram-bot >> "$LOG_FILE" 2>&1

# ── OpenClaw ──────────────────────────────────────────────────────────────────
OPENCLAW_DIR="$GRACEY_HOME/openclaw-src"

if [ -d "$OPENCLAW_DIR/.git" ]; then
    log "OpenClaw source already present. Pulling latest ($OPENCLAW_REF) ..."
    git -C "$OPENCLAW_DIR" fetch origin >> "$LOG_FILE" 2>&1
    git -C "$OPENCLAW_DIR" checkout "$OPENCLAW_REF" >> "$LOG_FILE" 2>&1
    git -C "$OPENCLAW_DIR" pull >> "$LOG_FILE" 2>&1
else
    log "Cloning OpenClaw from $OPENCLAW_REPO ..."
    git clone --branch "$OPENCLAW_REF" --depth 1 "$OPENCLAW_REPO" "$OPENCLAW_DIR" >> "$LOG_FILE" 2>&1
fi

if [ -f "$OPENCLAW_DIR/requirements.txt" ]; then
    log "Installing OpenClaw requirements.txt ..."
    pip install -r "$OPENCLAW_DIR/requirements.txt" >> "$LOG_FILE" 2>&1
fi

log "Installing OpenClaw package ..."
pip install -e "$OPENCLAW_DIR" >> "$LOG_FILE" 2>&1

# ── Directory layout ──────────────────────────────────────────────────────────
log "Ensuring Gracey directory layout ..."
mkdir -p "$GRACEY_HOME/models"
mkdir -p "$GRACEY_HOME/logs"
mkdir -p "$GRACEY_HOME/tmp"

# ── Smoke test ────────────────────────────────────────────────────────────────
log "Running smoke tests ..."
"$PYTHON" -c "import torch; assert torch.cuda.is_available(), 'CUDA not available'; \
              print('  torch OK  | CUDA device:', torch.cuda.get_device_name(0))"
"$PYTHON" -c "import transformers; print('  transformers OK | version:', transformers.__version__)"
"$PYTHON" -c "import fastapi;      print('  fastapi OK      | version:', fastapi.__version__)"

log ""
log "=== Installation complete ==="
log "Activate the environment with: source $GRACEY_VENV/bin/activate"
log "Next step: edit openclaw/openclaw_config.yaml then run openclaw/run_openclaw.sh"
