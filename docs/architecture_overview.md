# Gracey Architecture Overview

This document describes the refactored Gracey architecture designed for
NemoClaw-first operations with benchmark-driven runtime selection between vLLM
and TensorRT-LLM.

## High-Level Diagram

```text
┌──────────────────────────────────────────────────────────┐
│                      External Clients                     │
│  Telegram App │  Web UI │  CLI / API consumers           │
└───────┬───────┴──────┬──┴───────────────┬───────────────┘
        │              │                  │
        ▼              ▼                  ▼
┌──────────────────────────────────────────────────────────┐
│                 Interface Plane                           │
│     API Service (FastAPI) + Agent Connectors             │
└───────────────────────────┬──────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│                     Router Plane                          │
│  Classifier + Role Routing + Fallback + SLO Policies     │
└──────────────┬──────────────┬──────────────┬─────────────┘
               │              │              │
               ▼              ▼              ▼
         fast/heavy       thinker        architect
               \             |              /
                \            |             /
                 ▼           ▼            ▼
┌──────────────────────────────────────────────────────────┐
│                    Inference Plane                        │
│   vLLM workers  +  TensorRT-LLM workers (role-assigned)  │
└───────────────────────────┬──────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│                     Control Plane                         │
│      NemoClaw + OpenShell policy + lifecycle controls    │
└───────────────────────────┬──────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│                    DGX Spark / GB10                       │
│       Blackwell GPU + 128 GB unified memory              │
└──────────────────────────────────────────────────────────┘
```

## Planes and Responsibilities

### 1. Control Plane (`platform/control/`)

- Uses NemoClaw as the primary operational framework.
- Defines sandbox and egress controls via OpenShell policy.
- Handles lifecycle operations and policy enforcement.

### 2. Inference Plane (`platform/inference/`)

- Hosts model roles and runtime assignments.
- Supports both vLLM and TensorRT-LLM.
- Runtime winner is determined by benchmark data per role.

### 3. Router Plane (`platform/router/`)

- Classifies request complexity and intent.
- Routes requests to `fast`, `heavy`, `thinker`, or `architect` roles.
- Applies fallback behavior and timeout budgets.

### 4. Interface Plane (`interfaces/`)

- API service provides `/v1/chat`, `/v1/route`, and health endpoints.
- Telegram agent connector bridges user traffic into API.
- API and Telegram are intentionally redesigned in this refactor.

## Role Catalog

- `fast`: `nvidia/Qwen3-30B-A3B-FP4`
- `heavy`: `nvidia/Qwen3-32B-FP4`
- `thinker`: `nvidia/Phi-4-reasoning-plus-NVFP4`
- `architect`: `openai/gpt-oss-120b` and `nvidia/Llama-3.3-70B-Instruct-NVFP4`

## Data Flow

```text
User request
  -> Interface plane (API / Telegram)
  -> Router plane (classify and select role)
  -> Inference plane (runtime-selected worker)
  -> Model output
  -> Interface response
```

## Runtime Selection Policy

Runtime assignment is evaluated role-by-role with benchmark metrics:

- first-token latency
- p95 response latency
- tokens/sec throughput
- memory headroom
- cold-start penalty

vLLM is the default initial candidate for rapid integration and API
compatibility. TensorRT-LLM is promoted for a role if benchmark results are
better on the target hardware.

## Hardware Pending Mode

Until hardware is available, Gracey runs in `mock` mode:

- API returns scaffold responses.
- Router rules are testable with static policy files.
- Role registry can be validated without loading real models.

## Security Model

- Keep real secrets in environment variables only.
- Preserve protected file `secrets/GraYc.txt` unchanged.
- Keep inference endpoints internal and route traffic through policy-aware edge services.
