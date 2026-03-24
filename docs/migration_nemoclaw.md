# Gracey Migration to NemoClaw-First Architecture

This document tracks the hard-reset migration from the OpenClaw-centric scaffold
into a NemoClaw-first, role-routed serving platform.

## Goals

- Build and operate four assistants as first-class routes.
- Redesign both API and Telegram interfaces.
- Support role-based model routing: fast, heavy, thinker, architect.
- Select runtime by benchmark results on DGX Spark (vLLM vs TensorRT-LLM).
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

## Next Implementation Milestones

1. Build benchmark harness and collect role-by-role runtime winners.
2. Implement real router service with role classification + failover.
3. Stand up vLLM runtime wrappers for fast/thinker first.
4. Add TRT-LLM adapter path for roles where benchmarks win.
5. Integrate auth, rate limits, and structured tracing.
