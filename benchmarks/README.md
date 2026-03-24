# Benchmark Harness Plan

This folder contains benchmark inputs and output format contracts for runtime
arbitration (vLLM vs TensorRT-LLM) by role.

## Goals

- Measure runtime performance on target hardware per role.
- Select runtime winner for each role from objective metrics.

## Core Metrics

- TTFT (time to first token)
- p50 and p95 latency
- output tokens/sec
- memory utilization and headroom
- cold-start latency
- non-2xx or timeout error rate

## Expected Output

Write result summaries in `benchmarks/results/` as JSON:

- `fast_results.json`
- `heavy_results.json`
- `thinker_results.json`
- `architect_results.json`

Each result file should include model id, runtime, test set version, and metric values.
