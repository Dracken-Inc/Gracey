#!/usr/bin/env bash
set -euo pipefail

# Configure GraceyBlackwell for NemoClaw/OpenClaw multi-agent operation using
# vLLM as the backend.

INSTALL_DIR="/opt/gracey"
ENV_FILE=""
SECRETS_FILE=""
NODE_HOSTNAME="promaxgb10-4afb.local"
INSTALL_NEMOCLAW="false"
RUN_ONBOARD="false"

print_help() {
  cat <<'EOF'
Usage: setup_nemoclaw_graceyblackwell.sh [options]

Options:
  --install-dir <path>       Gracey install root (default: /opt/gracey)
  --env-file <path>          Env file with keys/tokens (default: <install-dir>/.env)
  --secrets-file <path>      Secrets file (default: <install-dir>/secrets/GraYc.txt)
  --node-hostname <name>     Expected node hostname (default: promaxgb10-4afb.local)
  --install-nemoclaw         Install NemoClaw/OpenShell if missing
  --onboard                  Run nemoclaw onboard after configuration
  -h, --help                 Show this help

Required env vars in env file:
  API_GATEWAY_AUTH_TOKEN
  TELEGRAM_BOT_TOKEN

Optional backend env vars:
  VLLM_BASE_URL (default: http://127.0.0.1:8000/v1)
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

fail() {
  log "ERROR: $*"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir)
      INSTALL_DIR="${2:-}"
      shift 2
      ;;
    --env-file)
      ENV_FILE="${2:-}"
      shift 2
      ;;
    --secrets-file)
      SECRETS_FILE="${2:-}"
      shift 2
      ;;
    --node-hostname)
      NODE_HOSTNAME="${2:-}"
      shift 2
      ;;
    --install-nemoclaw)
      INSTALL_NEMOCLAW="true"
      shift
      ;;
    --onboard)
      RUN_ONBOARD="true"
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

if [[ "$(id -u)" -ne 0 ]]; then
  fail "Run as root (use sudo)."
fi

if [[ -z "$ENV_FILE" ]]; then
  ENV_FILE="$INSTALL_DIR/.env"
fi

if [[ -z "$SECRETS_FILE" ]]; then
  SECRETS_FILE="$INSTALL_DIR/secrets/GraYc.txt"
fi

[[ -d "$INSTALL_DIR" ]] || fail "Install dir not found: $INSTALL_DIR"
[[ -f "$SECRETS_FILE" ]] || fail "Secrets file not found: $SECRETS_FILE"
[[ -s "$SECRETS_FILE" ]] || fail "Secrets file is empty: $SECRETS_FILE"
[[ -f "$ENV_FILE" ]] || fail "Env file not found: $ENV_FILE"

if [[ -f "$INSTALL_DIR/scripts/validate_env.sh" ]]; then
  log "Validating environment file"
  bash "$INSTALL_DIR/scripts/validate_env.sh" "$ENV_FILE"
fi

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

[[ -n "${API_GATEWAY_AUTH_TOKEN:-}" ]] || fail "API_GATEWAY_AUTH_TOKEN is required"
[[ -n "${TELEGRAM_BOT_TOKEN:-}" ]] || fail "TELEGRAM_BOT_TOKEN is required"

if [[ "$INSTALL_NEMOCLAW" == "true" ]]; then
  if command -v nemoclaw >/dev/null 2>&1 && command -v openshell >/dev/null 2>&1; then
    log "NemoClaw/OpenShell already installed"
  else
    log "Installing NemoClaw/OpenShell"
    curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash
  fi
fi

command -v nemoclaw >/dev/null 2>&1 || fail "nemoclaw command not found"
command -v openshell >/dev/null 2>&1 || fail "openshell command not found"

if [[ "$(hostname)" != "$NODE_HOSTNAME" ]]; then
  log "WARNING: Hostname is $(hostname), expected $NODE_HOSTNAME"
fi

VLLM_BASE_URL="${VLLM_BASE_URL:-http://127.0.0.1:8000/v1}"
RUNTIME_DIR="$INSTALL_DIR/.runtime"
mkdir -p "$RUNTIME_DIR"

log "Writing NemoClaw runtime environment"
cat > "$RUNTIME_DIR/graceyblackwell_nemoclaw.env" <<EOF
GRACEY_BACKEND=vllm
GRACEY_MULTI_AGENT=true
GRACEY_ASSISTANTS=fast,heavy,thinker,architect
GRACEY_LITTLE_INDIAN_ROLES=fast,thinker
GRACEY_BIG_INDIAN_ROLES=heavy,architect
VLLM_BASE_URL=$VLLM_BASE_URL
OLLAMA_ENABLED=false
SECRETS_FILE=$SECRETS_FILE
EOF

log "Backing up and writing role registry with vLLM runtime defaults"
ROLE_REGISTRY="$INSTALL_DIR/platform/inference/role_registry.yaml"
if [[ -f "$ROLE_REGISTRY" ]]; then
  cp "$ROLE_REGISTRY" "$ROLE_REGISTRY.bak.$(date +%Y%m%d%H%M%S)"
fi

cat > "$ROLE_REGISTRY" <<'EOF'
# role_registry.yaml
# GraceyBlackwell four-assistant map with vLLM as the primary backend.

runtime_selection_policy:
  method: "policy_locked"
  default_runtime: "vllm"
  disallowed_runtimes:
    - "ollama"

roles:
  - id: fast
    assistant_name: "Worker Fast"
    model: "nvidia/Qwen3-30B-A3B-FP4"
    runtime: "vllm"
    warm: true
    max_context_length: 16384
    max_output_tokens: 2048

  - id: heavy
    assistant_name: "Worker Heavy"
    model: "nvidia/Qwen3-32B-FP4"
    runtime: "vllm"
    warm: true
    max_context_length: 32768
    max_output_tokens: 4096

  - id: thinker
    assistant_name: "Thinker"
    model: "nvidia/Phi-4-reasoning-plus-NVFP4"
    runtime: "vllm"
    warm: true
    max_context_length: 32768
    max_output_tokens: 4096

  - id: architect
    assistant_name: "Architect"
    model: "nvidia/Llama-3.3-70B-Instruct-NVFP4"
    runtime: "vllm"
    warm: false
    max_context_length: 65536
    max_output_tokens: 4096
EOF

NEMO_PROFILE="$INSTALL_DIR/platform/control/nemoclaw_profile.yaml"
if [[ -f "$NEMO_PROFILE" ]]; then
  cp "$NEMO_PROFILE" "$NEMO_PROFILE.bak.$(date +%Y%m%d%H%M%S)"
fi

log "Writing NemoClaw control profile for vLLM backend"
cat > "$NEMO_PROFILE" <<EOF
# nemoclaw_profile.yaml
sandbox:
  name: "graceyblackwell"
  strict_mode: true
  network_policy_file: "platform/control/openshell_policy.yaml"

lifecycle:
  health_poll_seconds: 10
  restart_on_failure: true

providers:
  vllm:
    enabled: true
    endpoint: "$VLLM_BASE_URL"
  ollama:
    enabled: false

multi_agent:
  enabled: true
  assistants:
    - fast
    - heavy
    - thinker
    - architect
  escalation:
    little_indian:
      - fast
      - thinker
    big_indian:
      - heavy
      - architect

secrets:
  source_file: "$SECRETS_FILE"
  env_file: "$ENV_FILE"
EOF

if [[ "$RUN_ONBOARD" == "true" ]]; then
  if nemoclaw --help 2>/dev/null | grep -qi onboard; then
    log "Running nemoclaw onboard"
    nemoclaw onboard
  else
    log "WARNING: 'nemoclaw onboard' not available in this CLI version"
  fi
fi

log "GraceyBlackwell NemoClaw setup complete"
log "Backend locked to vLLM, Ollama disabled"
log "Runtime env file: $RUNTIME_DIR/graceyblackwell_nemoclaw.env"
log "Role registry: $ROLE_REGISTRY"
log "NemoClaw profile: $NEMO_PROFILE"