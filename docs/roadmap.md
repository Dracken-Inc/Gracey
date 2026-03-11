# Gracey-GB10 Roadmap

This document outlines planned improvements and future directions for the
Gracey-GB10 inference node, organised by approximate time horizon.

---

## Current Status (v0.1 — Initial Scaffold)

- [x] Project directory structure and documentation
- [x] GB10 environment setup guide
- [x] OpenClaw install script
- [x] Hardware profile JSON
- [x] Telegram bot integration guide
- [x] API Gateway placeholder
- [x] Service configuration (placeholders)
- [x] OpenClaw base configuration
- [x] System identity and lineage documentation

---

## Near-Term (v0.2 — First Running System)

_Target: when GB10 hardware arrives_

- [ ] Complete API Gateway implementation (`services/api_gateway/main.py`)
- [ ] Telegram bot working end-to-end against OpenClaw
- [ ] First model loaded and responding to queries
- [ ] Systemd service units for all three services
- [ ] Health-check endpoint and basic monitoring dashboard
- [ ] CI pipeline for linting and config validation

---

## Short-Term (v0.3 — Hardening)

- [ ] Authentication middleware with rotating API tokens
- [ ] Per-user rate limiting in the API Gateway
- [ ] Streaming responses (SSE) from OpenClaw through to Telegram
- [ ] Structured JSON logging with log rotation
- [ ] Prometheus metrics exporter and Grafana dashboard
- [ ] Automated model download helper script
- [ ] Integration test suite against a stub OpenClaw endpoint

---

## Medium-Term (v1.0 — Production-Ready)

- [ ] Multi-model support: hot-swap models without restarting the worker
- [ ] Conversation history and context management (per-user, persistent)
- [ ] Fine-tuning pipeline: LoRA adapters trained on GB10
- [ ] Web UI (lightweight chat interface served by the API Gateway)
- [ ] Discord bot integration alongside Telegram
- [ ] Container images (Docker) for each service component
- [ ] Helm chart or Compose file for reproducible deployments

---

## Long-Term (v2.0 — Multi-Node Cluster)

- [ ] **Multi-GB10 cluster**: tensor-parallel inference across two or more nodes
  connected via InfiniBand (ConnectX-7)
- [ ] Distributed KV-cache sharing between nodes
- [ ] Load balancer in front of multiple OpenClaw workers
- [ ] Federated identity: one user session spanning multiple nodes
- [ ] Model registry: versioned model artefacts with rollback support
- [ ] Automated hardware benchmarking suite for new GB10 units

---

## Research & Experimentation

- [ ] Benchmark Flash Attention 3 vs. standard attention on GB10
- [ ] Evaluate INT4 / FP8 quantisation trade-offs on Blackwell tensor cores
- [ ] Experiment with speculative decoding for lower latency
- [ ] Explore MoE (Mixture of Experts) models on unified memory
- [ ] Document GB10 performance baselines for common model sizes
  (7B, 13B, 34B, 70B, 110B+)

---

## Notes

- Priorities may shift based on hardware availability and community feedback.
- Contributions and feature requests are welcome via GitHub Issues.
- The roadmap is intentionally aspirational; items may be re-scoped or deferred.
