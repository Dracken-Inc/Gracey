# Runbook - promaxgb10-4afb.local

This runbook is an operator-focused command sequence for bringing Gracey online
on your current DGX Spark node.

## Node Identity

- Hostname: `promaxgb10-4afb.local`
- Network: Tailscale internal network
- Sync layer: NVIDIA Sync enabled

## 1. Baseline Health

```bash
hostname
nvidia-smi
docker --version
tailscale status
```

Run bundled preflight:

```bash
/opt/gracey/scripts/preflight_spark.sh promaxgb10-4afb.local
```

Expected:

- Host resolves as `promaxgb10-4afb.local`
- GPU visible in `nvidia-smi`
- Docker daemon responsive
- Tailscale peer state healthy

## 2. Control Plane Install and Verify

```bash
curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash
source ~/.bashrc
nemoclaw --help
openshell --help
nemoclaw onboard
nemoclaw <assistant-name> status
```

## 3. Gracey Bring-Up (Primary)

If this is a fresh node with no Gracey folders yet:

```bash
sudo apt-get update -y
sudo apt-get install -y git curl ca-certificates
sudo mkdir -p /opt
cd /opt
sudo git clone <your-gracey-repo-url> gracey
```

Then run scaffold plus setup in one command:

```bash
sudo bash /opt/gracey/scripts/bootstrap_gracey_spark.sh \
  --repo-url <your-gracey-repo-url> \
  --branch main \
  --install-dir /opt/gracey \
  --node-hostname promaxgb10-4afb.local \
  --install-nemoclaw \
  --run-nemoclaw-setup
```

Configure accounts and keys:

```bash
cp .env.example .env
# Edit .env and set real values for tokens/keys
set -a
source .env
set +a
```

Validate env before start:

```bash
/opt/gracey/scripts/validate_env.sh /opt/gracey/.env
```

Reference files:

- `configs/accounts_identity.yaml` for account names and handles
- `.env` for secret keys and tokens (local only)

`configs/gracey_stack.yaml` should already contain:

- `project.mode: hardware`
- `deployment.node_hostname: promaxgb10-4afb.local`

If you already ran bootstrap with `--run-nemoclaw-setup`, the multi-agent setup
is already applied. Re-run only if needed:

```bash
sudo bash /opt/gracey/scripts/setup_nemoclaw_graceyblackwell.sh \
  --install-dir /opt/gracey \
  --env-file /opt/gracey/.env \
  --secrets-file /opt/gracey/secrets/GraYc.txt \
  --node-hostname promaxgb10-4afb.local \
  --install-nemoclaw \
  --onboard
```

Confirm vLLM backend lock and no Ollama:

```bash
grep -n "runtime: \"vllm\"" /opt/gracey/platform/inference/role_registry.yaml
grep -n "ollama:" /opt/gracey/platform/control/nemoclaw_profile.yaml
grep -n "enabled: false" /opt/gracey/platform/control/nemoclaw_profile.yaml
```

Optional only: start API compatibility service

```bash
/opt/gracey/scripts/start_gracey_api.sh /opt/gracey
```

This API is an adapter path and is not the control plane.

## 4. Optional Endpoint Validation

If API adapter is running:

```bash
curl http://promaxgb10-4afb.local:8080/healthz
curl -X POST http://promaxgb10-4afb.local:8080/v1/route -H "Content-Type: application/json" -d '{"message":"plan multi-stage migration","role_hint":"auto"}'
curl -X POST http://promaxgb10-4afb.local:8080/v1/chat -H "Content-Type: application/json" -d '{"message":"analyze this failure chain and suggest mitigation","role_hint":"auto"}'
```

Verify in response:

- four-assistant routing fields
- lane selection (`little-indian` / `big-indian`)
- validation checks present

## 5. Runtime Bring-Up Sequence

1. Bring up `fast` and `thinker` workers.
2. Benchmark vLLM vs TRT-LLM for those roles.
3. Bring up `heavy` and `architect` workers.
4. Re-benchmark and lock runtime choices in role registry.

## 6. Safety and Rollback

- Keep `secrets/GraYc.txt` unchanged.
- Keep a backup of role registry before each runtime decision update.
- If failures occur, switch `project.mode` back to `mock` and re-validate endpoints.
