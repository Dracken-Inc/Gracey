# Gracey Setup Playbook

This playbook provides a detailed, practical path for installing and operating
Gracey on NVIDIA DGX Spark.

It is organized as two tracks:

- Track A: no-hardware development (can be done today)
- Track B: Spark hardware bring-up (execute when Spark is available)

## Scope

This playbook covers:

- Host prerequisites
- NemoClaw and OpenShell install flow
- Gracey install and mock validation
- Transition from mock mode to hardware mode
- Four-assistant runtime bring-up and validation
- Rollback and troubleshooting basics

## Recommended Root Folder Layout

If you begin at `/`, use this standard layout:

```text
/
|- opt/
|  |- gracey/          # Git repo root
|- var/
|  |- log/
|     |- gracey/       # Runtime and service logs
|- tmp/
|  |- gracey-bootstrap/
```

Detailed layout guide: `docs/root_folder_layout.md`.

## One-Command Bootstrap Script

Run this as root from `/` (or any directory):

```bash
sudo bash /path/to/Gracey/scripts/bootstrap_gracey_spark.sh \
  --repo-url <your-gracey-repo-url> \
  --branch main \
  --install-dir /opt/gracey \
  --node-hostname promaxgb10-4afb.local \
  --install-nemoclaw
```

If repo already exists at `/opt/gracey`, repo URL is optional:

```bash
sudo bash /opt/gracey/scripts/bootstrap_gracey_spark.sh --install-nemoclaw
```

What the script does:

- installs base packages
- creates `/opt/gracey`, `/var/log/gracey`, and `/tmp/gracey-bootstrap`
- clones or updates Gracey repo
- validates required files
- creates local `.env` from `.env.example` if missing
- creates API virtual environment and installs requirements
- optionally installs NemoClaw/OpenShell
- writes summary to `/tmp/gracey-bootstrap/summary.txt`

## Mandatory Preflight and Env Validation

Run these before starting services:

```bash
/opt/gracey/scripts/preflight_spark.sh promaxgb10-4afb.local
/opt/gracey/scripts/validate_env.sh /opt/gracey/.env
```

If either command fails, fix issues before continuing.

This playbook does not modify protected secrets content. Keep
`secrets/GraYc.txt` unchanged.

## Accounts and Keys Configuration

Use these files together:

- `.env.example`: key and token variable template (safe for git)
- `configs/accounts_identity.yaml`: public account names and handles
- `.env` (local only): real key material on your Spark node

Create local env file on Spark:

```bash
cp .env.example .env
```

Then set at least:

- `API_GATEWAY_AUTH_TOKEN`
- `TELEGRAM_BOT_TOKEN` (you already have this)
- `NVIDIA_API_KEY` only if using NVIDIA endpoints

Load environment variables before bring-up:

```bash
set -a
source .env
set +a
```

## Architecture Targets

Gracey runs four assistants:

- Worker Fast (`fast`)
- Worker Heavy (`heavy`)
- Thinker (`thinker`)
- Architect (`architect`)

Resource lanes:

- little-indian lane: `fast`, `thinker`
- big-indian lane: `heavy`, `architect`

Runtime policy:

- Benchmark plus policy (not benchmark-only)
- Runtime winner per assistant selected from vLLM or TRT-LLM

## Required Repository Files

Before starting, verify these files exist:

- `configs/gracey_stack.yaml`
- `platform/control/nemoclaw_profile.yaml`
- `platform/control/openshell_policy.yaml`
- `platform/inference/role_registry.yaml`
- `platform/router/routing_policy.yaml`
- `configs/accounts_identity.yaml`
- `.env.example`
- `interfaces/api/app/main.py`
- `scripts/run_api_mock.sh`
- `scripts/run_api_mock.ps1`

## Track A - No-Hardware Development

### A1. Prepare local dev environment

Linux/macOS:

```bash
cd /path/to/Gracey
./scripts/run_api_mock.sh
```

Windows PowerShell:

```powershell
Set-Location D:\AI\Gracey
./scripts/run_api_mock.ps1
```

### A2. Validate API health

```bash
curl http://localhost:8080/healthz
```

Expected indicators:

- `status: ok`
- `mode: mock`
- `assistants_count: 4`
- `resource_lanes` includes `little-indian` and `big-indian`

### A3. Validate routing and classifiers

```bash
curl -X POST http://localhost:8080/v1/route \
  -H "Content-Type: application/json" \
  -d '{"message":"design a migration architecture","role_hint":"auto"}'
```

Confirm response includes:

- `role_selected`
- `assistant_selected`
- `lane_selected`
- `classifier_used`
- `confidence`

### A4. Validate chat path and checksum behavior

```bash
curl -X POST http://localhost:8080/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"analyze this system and propose a phased plan","role_hint":"auto"}'
```

Confirm response includes:

- `validation.passed`
- `validation.score`
- checks under `validation.checks`

## Track B - DGX Spark Bring-Up

Run this track when hardware is available.

### B0. Current Node Context

This repository is currently targeting:

- Hostname: `promaxgb10-4afb.local`
- Internal network: Tailscale enabled
- NVIDIA Sync: enabled

Use this host as the primary endpoint during bring-up and verification.

### B1. Host prerequisites

Verify:

```bash
nvidia-smi
docker --version
```

Recommended baseline:

- Ubuntu 22.04+
- Docker installed and daemon running
- NVIDIA runtime stack healthy
- cgroup v2 configured per Spark guidance

Also verify hostname and internal resolution:

```bash
hostname
getent hosts promaxgb10-4afb.local || ping -c 1 promaxgb10-4afb.local
```

If Tailscale is used for access, verify peer state:

```bash
tailscale status
```

### B2. Install NemoClaw and OpenShell

```bash
curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash
```

Reload shell, then verify:

```bash
nemoclaw --help
openshell --help
```

### B3. Onboard control plane

```bash
nemoclaw onboard
```

Then check:

```bash
nemoclaw <assistant-name> status
```

If the sandbox is healthy, keep a short status snapshot:

```bash
nemoclaw <assistant-name> status > /tmp/gracey_nemoclaw_status.txt
```

### B4. Deploy Gracey on Spark

```bash
git clone <your-gracey-repo-url>
cd Gracey
```

Create and load your local `.env`:

```bash
cp .env.example .env
# Edit .env and set real token values
set -a
source .env
set +a
```

Start mock once first to validate repo integrity:

```bash
/opt/gracey/scripts/start_gracey_api.sh /opt/gracey
```

### B5. Switch to hardware mode

Edit `configs/gracey_stack.yaml`:

- verify `project.mode` is `hardware`
- keep `assistants_count: 4`
- keep resource management strategy as `big-indian-little-indian`
- verify `deployment.node_hostname` is `promaxgb10-4afb.local`

### B6. Bring up assistant runtimes in phases

Order:

1. Bring up little-indian lane (`fast`, `thinker`)
2. Run baseline tests
3. Bring up big-indian lane (`heavy`, `architect`)

For each assistant role:

- test vLLM path
- test TRT-LLM path
- record metrics

### B7. Select runtime per role

Use benchmark-plus-policy decision:

- TTFT
- p95 latency
- tokens/sec
- cold-start penalty
- error rate
- reliability and policy constraints

Update runtime assignment in `platform/inference/role_registry.yaml`.

### B8. Validate end-to-end behavior

Test both endpoints with realistic prompts:

- `/v1/route` for role and lane selection
- `/v1/chat` for response plus validation metadata

Confirm:

- expected assistant route
- expected lane route
- stable validation pass behavior

Node-specific verification commands:

```bash
curl http://promaxgb10-4afb.local:8080/healthz
curl -X POST http://promaxgb10-4afb.local:8080/v1/route -H "Content-Type: application/json" -d '{"message":"design a failover strategy","role_hint":"auto"}'
curl -X POST http://promaxgb10-4afb.local:8080/v1/chat -H "Content-Type: application/json" -d '{"message":"analyze this architecture and provide phased rollout","role_hint":"auto"}'
```

## Operational Guardrails

- Do not commit live secrets.
- Keep `secrets/GraYc.txt` unchanged.
- Avoid destructive operations during initial bring-up.
- Keep one known-good config snapshot before runtime changes.

## Rollback Plan

If hardware mode fails:

1. Revert `project.mode` to `mock` in `configs/gracey_stack.yaml`.
2. Restart API in mock mode.
3. Restore last known-good role registry from backup.
4. Re-run Track A checks.

## Troubleshooting

### API does not start

- Check Python environment setup in `interfaces/api`.
- Reinstall requirements from `interfaces/api/requirements.txt`.

### Router returns unexpected role

- Inspect `platform/router/routing_policy.yaml` rules.
- Test with explicit `role_hint` and compare against `auto`.

### Validation fails too often

- Inspect validators in `interfaces/api/app/validators.py`.
- Tune thresholds and markers for your expected outputs.

### Runtime decisions are unstable

- Ensure same prompt set and load conditions for each benchmark run.
- Record and compare multiple runs before committing runtime changes.

## Completion Criteria

Playbook is complete when:

- API health is stable
- four assistants route correctly
- lane selection behaves as expected
- checksum validation is observable and predictable
- runtime decisions are documented and reproducible
