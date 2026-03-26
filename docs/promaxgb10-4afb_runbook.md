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

## 3. Gracey Bring-Up

```bash
git clone <your-gracey-repo-url>
cd Gracey
```

Configure accounts and keys:

```bash
cp .env.example .env
# Edit .env and set real values for tokens/keys
set -a
source .env
set +a
```

Reference files:

- `configs/accounts_identity.yaml` for account names and handles
- `.env` for secret keys and tokens (local only)

`configs/gracey_stack.yaml` should already contain:

- `project.mode: hardware`
- `deployment.node_hostname: promaxgb10-4afb.local`

Start API service:

```bash
./scripts/run_api_mock.sh
```

Note: current API scaffold is runtime-agnostic and safe for initial validation.
Replace launcher with runtime-backed service once vLLM/TRT-LLM workers are ready.

## 4. Endpoint Validation

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
