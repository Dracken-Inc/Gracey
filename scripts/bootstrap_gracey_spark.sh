#!/usr/bin/env bash
set -euo pipefail

# Idempotent bootstrap for Gracey on DGX Spark.

REPO_URL=""
BRANCH="main"
INSTALL_DIR="/opt/gracey"
NODE_HOSTNAME="promaxgb10-4afb.local"
INSTALL_NEMOCLAW="false"

print_help() {
  cat <<'EOF'
Usage: bootstrap_gracey_spark.sh [options]

Options:
  --repo-url <url>           Git repo URL for Gracey (required)
  --branch <name>            Branch to pull (default: main)
  --install-dir <path>       Install root (default: /opt/gracey)
  --node-hostname <name>     Node hostname (default: promaxgb10-4afb.local)
  --install-nemoclaw         Install NemoClaw/OpenShell if not present
  -h, --help                 Show this help
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
    --repo-url)
      REPO_URL="${2:-}"
      shift 2
      ;;
    --branch)
      BRANCH="${2:-}"
      shift 2
      ;;
    --install-dir)
      INSTALL_DIR="${2:-}"
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
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

[[ -n "$REPO_URL" ]] || fail "--repo-url is required"

if [[ "$(id -u)" -ne 0 ]]; then
  fail "Run as root (use sudo)."
fi

OPERATOR_USER="${SUDO_USER:-root}"
if ! id "$OPERATOR_USER" >/dev/null 2>&1; then
  OPERATOR_USER="root"
fi

log "Bootstrapping Gracey on node: $NODE_HOSTNAME"
log "Operator user: $OPERATOR_USER"

export DEBIAN_FRONTEND=noninteractive

log "Installing base packages"
apt-get update -y
apt-get install -y git curl ca-certificates python3 python3-venv python3-pip jq

log "Creating directories"
mkdir -p "$INSTALL_DIR"
mkdir -p /var/log/gracey
mkdir -p /tmp/gracey-bootstrap
chown -R "$OPERATOR_USER":"$OPERATOR_USER" "$INSTALL_DIR"
chown -R "$OPERATOR_USER":"$OPERATOR_USER" /var/log/gracey

if [[ -d "$INSTALL_DIR/.git" ]]; then
  log "Repository exists, updating branch $BRANCH"
  sudo -u "$OPERATOR_USER" git -C "$INSTALL_DIR" fetch origin
  sudo -u "$OPERATOR_USER" git -C "$INSTALL_DIR" checkout "$BRANCH"
  sudo -u "$OPERATOR_USER" git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH"
else
  log "Cloning repository"
  sudo -u "$OPERATOR_USER" git clone --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi

REQUIRED_FILES=(
  "$INSTALL_DIR/configs/gracey_stack.yaml"
  "$INSTALL_DIR/configs/accounts_identity.yaml"
  "$INSTALL_DIR/platform/inference/role_registry.yaml"
  "$INSTALL_DIR/platform/router/routing_policy.yaml"
  "$INSTALL_DIR/interfaces/api/app/main.py"
  "$INSTALL_DIR/.env.example"
)

log "Validating required files"
for f in "${REQUIRED_FILES[@]}"; do
  [[ -f "$f" ]] || fail "Missing required file: $f"
done

if [[ ! -f "$INSTALL_DIR/.env" ]]; then
  log "Creating local .env from template"
  sudo -u "$OPERATOR_USER" cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  log "Populate tokens in: $INSTALL_DIR/.env"
else
  log "Local .env already exists; leaving unchanged"
fi

log "Preparing API virtual environment"
API_DIR="$INSTALL_DIR/interfaces/api"
if [[ ! -d "$API_DIR/.venv" ]]; then
  sudo -u "$OPERATOR_USER" python3 -m venv "$API_DIR/.venv"
fi
sudo -u "$OPERATOR_USER" "$API_DIR/.venv/bin/python" -m pip install --upgrade pip
sudo -u "$OPERATOR_USER" "$API_DIR/.venv/bin/pip" install -r "$API_DIR/requirements.txt"

if [[ "$INSTALL_NEMOCLAW" == "true" ]]; then
  if command -v nemoclaw >/dev/null 2>&1; then
    log "NemoClaw already installed"
  else
    log "Installing NemoClaw"
    curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash
  fi
fi

log "Writing bootstrap summary"
cat > /tmp/gracey-bootstrap/summary.txt <<EOF
Node hostname target: $NODE_HOSTNAME
Install dir: $INSTALL_DIR
Operator user: $OPERATOR_USER
Repo branch: $BRANCH
NemoClaw install requested: $INSTALL_NEMOCLAW

Next steps:
1) Edit $INSTALL_DIR/.env with real keys and tokens.
2) Load env: set -a; source $INSTALL_DIR/.env; set +a
3) Run: $INSTALL_DIR/scripts/run_api_mock.sh
4) Validate: curl http://$NODE_HOSTNAME:8080/healthz
EOF

log "Bootstrap complete"
log "Summary: /tmp/gracey-bootstrap/summary.txt"
