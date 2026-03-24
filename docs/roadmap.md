# Gracey Roadmap (NemoClaw Refactor)

This roadmap tracks the hard-reset migration to a NemoClaw-first architecture
with role-based runtime arbitration between vLLM and TensorRT-LLM.

## Current Status (v0.2 — Refactor Scaffold)

- [x] New architecture scaffold for control, inference, router, and interfaces
- [x] Global stack config (`configs/gracey_stack.yaml`)
- [x] Role registry for fast/heavy/thinker/architect
- [x] Router policy skeleton with fallback rules
- [x] Mock API for pre-hardware development
- [x] Telegram bridge stub for integration testing
- [x] Migration document and no-hardware startup scripts
- [x] Legacy OpenClaw assets retained for reference

## Near-Term (v0.3 — Local Functional Prototype)

### Target Window (Pre-Hardware)

Before hardware arrives.

- [ ] Implement real router service from `routing_policy.yaml`
- [ ] Add API auth and per-user rate limiting middleware
- [ ] Add structured request IDs and JSON logging
- [ ] Add benchmark harness skeleton with replayable test prompts
- [ ] Add mock runtime adapters for vLLM and TensorRT-LLM contracts
- [ ] Add CI checks for YAML and Python lint/type validation

## Hardware Arrival Phase (v0.4 — Spark Bring-Up)

### Target Window (Hardware Bring-Up)

First week with DGX Spark access.

- [ ] Validate NemoClaw/OpenShell install path on target host
- [ ] Stand up vLLM for `fast` and `thinker` roles
- [ ] Run role baseline benchmarks for all target models
- [ ] Bring up TensorRT-LLM path for role-by-role comparison
- [ ] Select runtime winner per role and lock in role registry
- [ ] Enable health dashboards and role-level SLO tracking

## Short-Term (v0.5 — Production Candidate)

- [ ] Implement streaming responses on API and Telegram
- [ ] Add warm pool manager for `heavy` and `architect` roles
- [ ] Add failover policies for runtime and model unavailability
- [ ] Add policy conformance tests for OpenShell egress controls
- [ ] Build deployment templates (systemd and compose)

## Medium-Term (v1.0 — Stable Single-Node Production)

- [ ] End-to-end reliability testing under mixed role workloads
- [ ] Persistent conversation/context management by user and role
- [ ] Complete operations playbooks and incident runbooks
- [ ] Full observability: p95 latency, TTFT, tok/s, cold-start events

## Long-Term (v2.0 — Multi-Node Expansion)

- [ ] Multi-node inference scaling and scheduler-aware routing
- [ ] Role-aware load balancing across nodes
- [ ] Shared model/artifact registry and rollback strategy
- [ ] Automated re-benchmarking on runtime/model updates

## Notes

- Runtime selection is empirical and hardware-specific.
- Preserve `secrets/GraYc.txt` exactly through every migration stage.
- Legacy OpenClaw docs/scripts stay available until parity is reached.
