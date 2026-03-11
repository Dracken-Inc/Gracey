# Gracey-GB10

A clean, modular, hardware-aware starter project for deploying
[OpenClaw](https://github.com/openclaw/openclaw) on an
**NVIDIA Grace Blackwell GB10** local inference node named **Gracey-GB10**.

Named after **David Harold Blackwell** — statistician, game theorist, and trailblazer.

---

## Repository Layout

```
Gracey/
├── infrastructure/          # Hardware setup, install scripts, and hardware profile
│   ├── setup_gb10_environment.md   # Prepare a fresh GB10 system
│   ├── openclaw_install.sh         # Install OpenClaw and all dependencies
│   └── hardware_profile.json       # GB10 hardware capabilities reference
│
├── services/                # External-facing service integrations
│   ├── telegram_bot/
│   │   └── README.md               # Connect a Telegram bot via BotFather
│   ├── api_gateway/
│   │   └── README.md               # REST/WebSocket gateway (placeholder)
│   └── service_config.yaml         # Central config: ports, tokens, routing
│
├── openclaw/                # Inference worker configuration and launcher
│   ├── openclaw_config.yaml        # Model, memory, workers, sampling
│   ├── models/
│   │   └── README.md               # Where to place local model files
│   └── run_openclaw.sh             # Start OpenClaw with GB10-optimised flags
│
├── identity/                # System identity and naming
│   ├── gracey_identity.md          # Who/what Gracey-GB10 is and why
│   └── service_usernames.md        # Recommended handles across platforms
│
├── docs/                    # Project documentation
│   ├── architecture_overview.md    # How components interact
│   └── roadmap.md                  # Future expansion plans
│
├── README.md                # This file
├── .gitignore
└── LICENSE
```

---

## Quick-Start

> **Prerequisites:** GB10 hardware with Ubuntu 22.04+ installed.

### 1. Prepare the System

Follow [`infrastructure/setup_gb10_environment.md`](infrastructure/setup_gb10_environment.md)
to install NVIDIA drivers, CUDA 12.6, Python 3.11, and set required environment variables.

### 2. Install OpenClaw

```bash
chmod +x infrastructure/openclaw_install.sh
./infrastructure/openclaw_install.sh
```

### 3. Configure OpenClaw

Edit [`openclaw/openclaw_config.yaml`](openclaw/openclaw_config.yaml) to point
`model.path` at your local model directory (see
[`openclaw/models/README.md`](openclaw/models/README.md) for download instructions).

### 4. Configure Services

Copy and populate the service secrets (never commit real tokens):

```bash
cp services/service_config.yaml .env.example
# Edit .env with your real TELEGRAM_BOT_TOKEN, API_GATEWAY_AUTH_TOKEN, etc.
```

### 5. Start OpenClaw

```bash
chmod +x openclaw/run_openclaw.sh
./openclaw/run_openclaw.sh
```

### 6. Connect the Telegram Bot

Follow [`services/telegram_bot/README.md`](services/telegram_bot/README.md) to
register your bot with BotFather and start the bot service.

---

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture Overview](docs/architecture_overview.md) | Component interaction diagram and data flow |
| [Roadmap](docs/roadmap.md) | Planned features and multi-node expansion |
| [GB10 Setup](infrastructure/setup_gb10_environment.md) | Driver, CUDA, and Python setup |
| [Hardware Profile](infrastructure/hardware_profile.json) | GB10 specs and OpenClaw limits |
| [System Identity](identity/gracey_identity.md) | Who Gracey-GB10 is and its lineage |

---

## Security

- All secrets are environment variables — never committed to this repository.
- The OpenClaw worker binds to `127.0.0.1` only; the API Gateway handles external access.
- See [`services/service_config.yaml`](services/service_config.yaml) for placeholder structure.

---

## License

MIT — see [LICENSE](LICENSE).

---

## Operator

**Dracken Inc.** · [github.com/Dracken-Inc](https://github.com/Dracken-Inc)

