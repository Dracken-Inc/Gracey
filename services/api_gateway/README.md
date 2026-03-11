# API Gateway — Placeholder

This directory will contain the REST and/or WebSocket gateway that sits between
external clients (Telegram bot, web UI, CLI tools) and the OpenClaw inference
worker running on the GB10 node.

---

## Planned Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/v1/chat` | Single-turn chat message → OpenClaw inference |
| `POST` | `/v1/chat/stream` | Streaming chat response (SSE) |
| `POST` | `/v1/complete` | Raw completion (prompt → tokens) |
| `GET`  | `/v1/models` | List available loaded models |
| `GET`  | `/healthz` | Health check |

---

## Technology Options

- **FastAPI** (Python) — recommended; matches the rest of the Python stack
- **Express / Hono** (Node / TypeScript) — if a JS ecosystem is preferred
- **Nginx** — can be used as a reverse proxy in front of either option

---

## Planned Files

```
api_gateway/
├── README.md          ← this file
├── main.py            ← FastAPI application entry point
├── routers/
│   ├── chat.py        ← /v1/chat and /v1/chat/stream
│   └── models.py      ← /v1/models
├── middleware/
│   ├── auth.py        ← token-based authentication
│   └── rate_limit.py  ← per-user rate limiting
├── openclaw_client.py ← thin async wrapper around the OpenClaw worker socket
└── requirements.txt   ← pinned dependencies
```

---

## Configuration

The gateway reads from `../service_config.yaml`.  Key settings:

```yaml
api_gateway:
  host: "0.0.0.0"
  port: 8080
  workers: 2
  auth_token: "${API_GATEWAY_AUTH_TOKEN}"
```

---

## Next Steps

1. Implement `main.py` with a minimal FastAPI skeleton.
2. Wire `openclaw_client.py` to the OpenClaw process socket or HTTP endpoint.
3. Add token authentication middleware.
4. Write integration tests against the running OpenClaw worker.
