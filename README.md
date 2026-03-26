# Gracey

Gracey is a NemoClaw-first, role-routed local AI platform scaffold for NVIDIA
DGX Spark / GB10 class hardware.

This refactor moves Gracey from a single OpenClaw worker layout to a multi-role
architecture with benchmark-driven runtime arbitration between vLLM and
TensorRT-LLM.

This project is intentionally built around four assistants, not one.

Named after **David Harold Blackwell** - statistician, game theorist, and trailblazer.

## Current Stage

- Hardware status: not yet available.
- Development mode: mock-first, local API stubs.
- Migration style: hard reset scaffold with legacy files retained.
- Protected artifact: `secrets/GraYc.txt` is explicitly preserved.

---

## Repository Layout (Refactor Scaffold)

```text
Gracey/
|- configs/
|  |- gracey_stack.yaml                 # Global stack mode and control-plane settings
|
|- platform/
|  |- control/
|  |  |- nemoclaw_profile.yaml          # NemoClaw/OpenShell control profile
|  |  |- openshell_policy.yaml          # Baseline policy scaffold
|  |- inference/
|  |  |- role_registry.yaml             # fast/heavy/thinker/architect role map
|  |  |- runtimes/
|  |     |- vllm/profile.yaml           # vLLM runtime profile scaffold
|  |     |- trtllm/profile.yaml         # TensorRT-LLM runtime profile scaffold
|  |- router/
|     |- routing_policy.yaml            # Role routing and fallback policy
|
|- interfaces/
|  |- api/
|  |  |- app/main.py                    # Mockable API service scaffold
|  |  |- requirements.txt
|  |- agents/
|     |- telegram/
|        |- bot_stub.py                 # Telegram bridge scaffold
|        |- requirements.txt
|
|- ops/
|  |- deploy/docker-compose.mock.yml    # Mock deployment template
|  |- observability/prometheus.yml      # Observability scaffold
|
|- scripts/
|  |- run_api_mock.ps1                  # Windows mock API launcher
|  |- run_api_mock.sh                   # Linux mock API launcher
|
|- docs/
|  |- architecture_overview.md
|  |- migration_nemoclaw.md
|  |- roadmap.md
|  |- no_hardware_development.md
|
|- benchmarks/
|- identity/
|- infrastructure/                      # Legacy install/setup docs retained
|- openclaw/                            # Legacy OpenClaw assets retained
|- services/                            # Legacy services layout retained
|- secrets/                             # Do not modify or delete protected files
|- .gitignore
|- LICENSE
|- README.md
```

---

## Quick Start Without Hardware

### 1. Start the mock API (Windows PowerShell)

```powershell
./scripts/run_api_mock.ps1
```

### 2. Verify health endpoint

```powershell
Invoke-WebRequest http://localhost:8080/healthz
```

### 3. Test chat route

```powershell
Invoke-RestMethod http://localhost:8080/v1/chat -Method Post -ContentType application/json -Body '{"message":"hello","user_id":"dev","role_hint":"auto"}'
```

### 4. Optional Linux/macOS start

```bash
chmod +x scripts/run_api_mock.sh
./scripts/run_api_mock.sh
```

---

## Strategy Summary

### Four Assistants

- `fast`: Qwen3-30B-A3B NVFP4
- `heavy`: Qwen3-32B NVFP4
- `thinker`: Phi-4-Reasoning-Plus NVFP4
- `architect`: GPT-OSS-120B MXFP4 and Llama-3.3-70B NVFP4

Runtime choice is role-specific and benchmark-driven:

- vLLM and TensorRT-LLM are both first-class.
- Runtime winner per role is chosen by p95 latency, first-token latency,
  throughput, memory headroom, and cold-start penalty.
- Benchmark numbers alone are not enough; policy and reliability constraints
    are also part of runtime selection.

---

## Documentation

| Document | Description |
| -------- | ----------- |
| [Architecture Overview](docs/architecture_overview.md) | Refactored control/inference/router/interface design |
| [Setup Playbook](docs/setup_gracey_playbook.md) | Detailed installation and bring-up guide for mock and Spark phases |
| [Setup Checklist](docs/setup_gracey_checklist.md) | Step-by-step execution checklist for setup and validation |
| [Node Runbook](docs/promaxgb10-4afb_runbook.md) | Command-driven runbook for host `promaxgb10-4afb.local` |
| [Migration Plan](docs/migration_nemoclaw.md) | Hard-reset migration notes and progress |
| [Roadmap](docs/roadmap.md) | Refactor milestones from scaffold to production |
| [No-Hardware Development](docs/no_hardware_development.md) | Development flow before DGX Spark arrives |
| [Accounts Identity Config](configs/accounts_identity.yaml) | Public account names and service handles for this deployment |
| [.env Template](.env.example) | Required key/token variables for local node configuration |
| [Hardware Profile](infrastructure/hardware_profile.json) | GB10 specs reference |
| [System Identity](identity/gracey_identity.md) | Gracey lineage and purpose |

---

## Security

- Keep all real secrets in environment variables, never in repository files.
- Preserve `secrets/GraYc.txt` exactly; it is a protected artifact.
- Keep inference workers on localhost behind the API/router edge.

---

## License

MIT - see [LICENSE](LICENSE).

---

## Operator

**Dracken Inc.** · [github.com/Dracken-Inc](https://github.com/Dracken-Inc)
