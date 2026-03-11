# Gracey-GB10 Architecture Overview

This document explains how the system components interact to deliver local AI
inference through the Gracey-GB10 node.

---

## High-Level Diagram

```
┌──────────────────────────────────────────────────────────┐
│                      External Clients                     │
│  Telegram App │  Web Browser │  CLI / API consumer       │
└───────┬───────┴──────┬───────┴────────────────┬──────────┘
        │              │                         │
        ▼              ▼                         ▼
┌───────────────┐  ┌─────────────────────────────────────┐
│ Telegram Bot  │  │          API Gateway                │
│ (python-      │  │    FastAPI · host 0.0.0.0:8080      │
│  telegram-bot)│  │    Auth · Rate Limiting · Routing   │
└───────┬───────┘  └──────────────┬──────────────────────┘
        │                          │
        └──────────┬───────────────┘
                   │  HTTP POST /v1/chat
                   ▼
        ┌──────────────────────┐
        │   OpenClaw Worker    │
        │  127.0.0.1:9000      │
        │  Workers: 4          │
        │  Flash Attention 3   │
        └──────────┬───────────┘
                   │  PyTorch / CUDA
                   ▼
        ┌──────────────────────┐
        │   GB10 Hardware      │
        │  Grace CPU  72 cores │
        │  Blackwell GPU       │
        │  128 GB unified RAM  │
        └──────────────────────┘
```

---

## Component Descriptions

### 1. Telegram Bot (`services/telegram_bot/`)

- Written in Python using `python-telegram-bot`.
- Receives messages from users via the Telegram API (long-polling or webhook).
- Forwards each message as a JSON POST to the API Gateway.
- Returns the inference response to the user.
- Runs as a systemd service (`gracey-telegram-bot`).

### 2. API Gateway (`services/api_gateway/`)

- FastAPI application listening on `0.0.0.0:8080`.
- Handles authentication (Bearer token), rate limiting, and request validation.
- Translates incoming REST requests into the format expected by OpenClaw.
- Proxies requests to the OpenClaw worker at `127.0.0.1:9000`.
- Supports both standard JSON responses and Server-Sent Events (SSE) streaming.
- Runs as a systemd service (`gracey-api`).

### 3. OpenClaw Worker (`openclaw/`)

- Runs the AI model using the OpenClaw inference framework.
- Configured via `openclaw/openclaw_config.yaml`.
- Exposes a local HTTP interface on `127.0.0.1:9000` (not publicly accessible).
- Manages GPU memory, KV-cache, batching, and worker threads.
- Takes advantage of GB10 hardware features:
  - Flash Attention 3
  - Unified CPU+GPU memory (no data copies between separate pools)
  - NVLink bandwidth
- Runs as a systemd service (`gracey-openclaw`).

### 4. GB10 Hardware

- NVIDIA Grace Blackwell GB10 superchip.
- 72-core Grace ARM CPU + Blackwell GPU sharing 128 GB LPDDR5X.
- PyTorch accesses the GPU via CUDA 12.6+.
- Full hardware profile in `infrastructure/hardware_profile.json`.

---

## Data Flow

```
User message (Telegram)
  → Telegram Bot
    → API Gateway (auth check, rate limit)
      → OpenClaw Worker (inference)
        → GB10 GPU (model execution)
      ← OpenClaw response (tokens)
    ← API Gateway (JSON / SSE response)
  ← Telegram Bot (reply message)
← User (reply in Telegram)
```

---

## Configuration Files

| File | Purpose |
|------|---------|
| `services/service_config.yaml` | Ports, tokens, routing for all services |
| `openclaw/openclaw_config.yaml` | Model, memory, worker, sampling settings |
| `infrastructure/hardware_profile.json` | GB10 capability reference |

---

## Security Model

- The OpenClaw worker is **only reachable on localhost** (127.0.0.1:9000).
- External traffic enters only through the API Gateway, which enforces
  authentication before forwarding requests.
- All secrets (bot tokens, auth tokens) are stored as environment variables
  and never committed to version control.

---

## Service Dependencies

```
gracey-openclaw  ←── must start before ──→  gracey-api  ←── must start before ──→  gracey-telegram-bot
```

Systemd `After=` directives enforce this order automatically.
