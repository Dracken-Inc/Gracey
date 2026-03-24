# pyright: reportMissingImports=false

import os
import httpx
from telegram.ext import ApplicationBuilder, MessageHandler, filters, ContextTypes

API_URL = os.getenv("GRACEY_API_URL", "http://localhost:8080/v1/chat")


async def handle_message(update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_text = (update.message.text or "").strip()
    if not user_text:
        return

    async with httpx.AsyncClient() as client:
        response = await client.post(
            API_URL,
            json={
                "message": user_text,
                "user_id": str(update.effective_user.id),
                "role_hint": "auto",
            },
            timeout=30,
        )
        response.raise_for_status()

    reply = response.json().get("reply", "No response")
    await update.message.reply_text(reply)


def main() -> None:
    token = os.environ.get("TELEGRAM_BOT_TOKEN")
    if not token:
        raise RuntimeError("TELEGRAM_BOT_TOKEN is required")

    app = ApplicationBuilder().token(token).build()
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    app.run_polling()


if __name__ == "__main__":
    main()
