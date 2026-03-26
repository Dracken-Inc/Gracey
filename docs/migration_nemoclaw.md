# Gracey Migration to NemoClaw-First Architecture

This document tracks the hard-reset migration from the OpenClaw-centric scaffold
into a NemoClaw-first, role-routed serving platform.

## Goals

- Build and operate four assistants as first-class routes.
- Make NemoClaw/OpenClaw the primary execution path (not optional).
- Redesign both API and Telegram interfaces.
- Support role-based model routing: fast, heavy, thinker, architect.
- Use vLLM as default backend and explicitly disable Ollama.
- Select runtime by benchmark results on DGX Spark (vLLM vs TensorRT-LLM) after stable bring-up.
- Enable pre-hardware development in mock mode.

## Runtime Principle

- Benchmark metrics are required but not sufficient.
- Final runtime choice per assistant must include policy, reliability, and
  operational constraints.

## Rules

- Preserve `secrets/GraYc.txt` exactly.
- Avoid deleting legacy assets until equivalent replacements are validated.
- Keep secrets in environment variables only.

## Current Scaffold State

- New stack config: `configs/gracey_stack.yaml`
- Role registry: `platform/inference/role_registry.yaml`
- Control policy profiles: `platform/control/*.yaml`
- Router policy: `platform/router/routing_policy.yaml`
- Mock API: `interfaces/api/app/main.py`
- Telegram stub: `interfaces/agents/telegram/bot_stub.py`
- Primary setup command: `scripts/setup_nemoclaw_graceyblackwell.sh`

## Next Implementation Milestones

1. Run `setup_nemoclaw_graceyblackwell.sh` on Spark and verify multi-agent status.
2. Start vLLM workers per role and validate routing behavior under load.
3. Build benchmark harness and collect role-by-role runtime winners.
4. Add TRT-LLM adapter path only for roles where benchmarks win.
5. Keep API service as compatibility adapter, not control plane.
