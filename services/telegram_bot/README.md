# Telegram Bot — Setup Guide

This document explains how to connect a Telegram bot to the Gracey-GB10 inference
node using a token obtained from BotFather.

---

## 1. Create the Bot with BotFather

1. Open Telegram and search for **@BotFather**.
2. Send the command `/newbot`.
3. Follow the prompts:
   - **Name**: `Gracey GB10` (display name, can contain spaces)
   - **Username**: `GraceyGB10Bot` (must end in `bot`, no spaces)
4. BotFather will reply with an **API token** that looks like:
   ```
   1234567890:ABCDefGhIJKlmNoPQRsTUVwxyZ
   ```
5. **Keep this token secret.** Do not commit it to git.

---

## 2. Store the Token Securely

Place the token in one of the following locations (in order of preference):

### Option A — Environment Variable (recommended)

```bash
export TELEGRAM_BOT_TOKEN="<your-token-here>"
```

Add to `~/.bashrc` or a `.env` file that is listed in `.gitignore`.

### Option B — Service Config (placeholder only)

Open `services/service_config.yaml` and set:

```yaml
telegram:
  bot_token: "${TELEGRAM_BOT_TOKEN}"
```

The application reads this as an environment-variable reference at runtime.

---

## 3. Install the Bot Library

The `openclaw_install.sh` script already installs `python-telegram-bot`.
If you need to install it manually:

```bash
pip install python-telegram-bot
```

---

## 4. Basic Bot Skeleton

A minimal bot that forwards messages to the OpenClaw API gateway:

```python
import os
from telegram import Update
from telegram.ext import ApplicationBuilder, MessageHandler, filters, ContextTypes
import httpx

OPENCLAW_API = os.getenv("OPENCLAW_API_URL", "http://localhost:8080/v1/chat")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_text = update.message.text
    async with httpx.AsyncClient() as client:
        response = await client.post(
            OPENCLAW_API,
            json={"message": user_text, "user_id": str(update.effective_user.id)},
            timeout=60,
        )
    reply = response.json().get("reply", "No response.")
    await update.message.reply_text(reply)


def main() -> None:
    token = os.environ["TELEGRAM_BOT_TOKEN"]
    app = ApplicationBuilder().token(token).build()
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    print("Bot is running ...")
    app.run_polling()


if __name__ == "__main__":
    main()
```

Save this as `services/telegram_bot/bot.py` and run:

```bash
python services/telegram_bot/bot.py
```

---

## 5. Running as a systemd Service

Create `/etc/systemd/system/gracey-telegram-bot.service`:

```ini
[Unit]
Description=Gracey-GB10 Telegram Bot
After=network.target gracey-openclaw.service

[Service]
User=<your-user>
WorkingDirectory=/opt/gracey
EnvironmentFile=/opt/gracey/.env
ExecStart=/home/<your-user>/gracey-env/bin/python /opt/gracey/services/telegram_bot/bot.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now gracey-telegram-bot
sudo systemctl status gracey-telegram-bot
```

---

## 6. Useful BotFather Commands

| Command | Purpose |
|---------|---------|
| `/setdescription` | Set the bot's public description |
| `/setabouttext` | Short bio shown on the bot's profile |
| `/setuserpic` | Upload a profile picture |
| `/setcommands` | Register slash-command menu items |
| `/mybots` | List all bots you own |
