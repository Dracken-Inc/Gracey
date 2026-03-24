# Runtime Selection Formula

Use a lower-is-better weighted score to rank runtime candidates by role:

```text
score =
  0.35 * p95_latency_ms +
  0.30 * ttft_ms +
  0.20 * inverse_tokens_per_second +
  0.10 * cold_start_ms +
  0.05 * error_rate_percent
```

`inverse_tokens_per_second` can be computed as `1000 / tokens_per_second`.

## Decision Rule

1. Compare vLLM and TRT-LLM for each role independently.
2. Select the lower score winner.
3. If scores are within 5 percent, prefer the runtime with better operational simplicity.
