# No-Hardware Development Guide

This guide is for developing Gracey before DGX Spark hardware is available.

## What Works Today

- API contract and route behavior in mock mode
- Role routing policy editing and validation
- Telegram-to-API integration testing against mock responses
- Config and migration workflow validation
- Modular agentic router with:
  - Fast rule-based classifier
  - Deep reasoning classifier fallback
  - Big-indian and little-indian resource lane selection
  - Checksum validation for hallucination risk and consistency

## Start Mock API

### Windows

```powershell
./scripts/run_api_mock.ps1
```

### Linux/macOS

```bash
./scripts/run_api_mock.sh
```

## Test Endpoints

```powershell
Invoke-WebRequest http://localhost:8080/healthz
Invoke-RestMethod http://localhost:8080/v1/route -Method Post -ContentType application/json -Body '{"message":"design this system","role_hint":"auto"}'
Invoke-RestMethod http://localhost:8080/v1/chat -Method Post -ContentType application/json -Body '{"message":"hello","role_hint":"fast"}'
```

## What Is Deferred Until Hardware Arrives

- vLLM and TensorRT-LLM runtime performance testing
- Model loading and memory pressure tuning
- Runtime winner selection by role
- End-to-end throughput and SLO certification
