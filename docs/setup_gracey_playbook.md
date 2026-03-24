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

This playbook does not modify protected secrets content. Keep
`secrets/GraYc.txt` unchanged.

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

### B4. Deploy Gracey on Spark

```bash
git clone <your-gracey-repo-url>
cd Gracey
```

Start mock once first to validate repo integrity:

```bash
./scripts/run_api_mock.sh
```

### B5. Switch to hardware mode

Edit `configs/gracey_stack.yaml`:

- set `project.mode` to `hardware`
- keep `assistants_count: 4`
- keep resource management strategy as `big-indian-little-indian`

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
