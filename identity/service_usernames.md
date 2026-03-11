# Gracey-GB10 — Recommended Service Usernames

This document lists recommended handles across platforms for the Gracey-GB10 system
and its associated services operated by Dracken Inc.

> **Note:** Availability of usernames must be verified on each platform before
> registration. These are recommendations only.

---

## Platform Handles

| Platform  | Recommended Handle | Notes |
|-----------|--------------------|-------|
| **Telegram** | `@GraceyGB10Bot` | Primary inference bot; created via BotFather |
| **Telegram (channel)** | `@GraceyGB10` | Public announcements channel (optional) |
| **GitHub** | `gracey-gb10` | Org or repo suffix; main repo under `Dracken-Inc/Gracey` |
| **GitHub (org)** | `Dracken-Inc` | Existing org; keep all Gracey repos under this org |
| **Meta / Instagram** | `@gracey.gb10` | Optional social presence |
| **X / Twitter** | `@GraceyGB10` | Optional developer updates feed |
| **Discord** | `GraceyGB10#0000` | Community / dev support server |
| **Docker Hub** | `drackeninc/gracey-gb10` | Container images for services |
| **PyPI** | `gracey-gb10` | Python SDK package (future) |
| **npm** | `gracey-gb10` | JS/TS SDK (future, if needed) |

---

## Naming Conventions

- All public-facing handles use the pattern **`gracey-gb10`** (lowercase, hyphenated)
  or **`GraceyGB10`** (CamelCase) depending on platform norms.
- Internal service names (e.g., Docker containers, systemd units) use
  `gracey-<service>`, e.g., `gracey-api`, `gracey-bot`, `gracey-openclaw`.

---

## Bot Registration Steps (Telegram)

1. Open Telegram and search for `@BotFather`.
2. Send `/newbot` and follow the prompts.
3. Use `GraceyGB10Bot` as the bot name when prompted.
4. Copy the API token and place it in `services/service_config.yaml` under
   `telegram.bot_token` (never commit real tokens to git).

---

## Username Reservation Checklist

- [ ] `@GraceyGB10Bot` registered on Telegram
- [ ] `@GraceyGB10` channel created on Telegram (optional)
- [ ] `drackeninc/gracey-gb10` namespace claimed on Docker Hub
- [ ] `gracey-gb10` package name reserved on PyPI (optional)
- [ ] Social handles registered as needed
