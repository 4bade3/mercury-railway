# Mercury Railway — Setup Guide

## Step 1: Deploy

Click **Deploy on Railway** in the README, or go to:

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/kJGxP-?referralCode=u71AUL&utm_medium=integration&utm_source=template&utm_campaign=generic)

Fill in the variables Railway shows you. At minimum:

- `MERCURY_OWNER` — your name
- `DEFAULT_PROVIDER` — pick `anthropic`, `deepseek`, `openai`, or `grok`
- The API key for your chosen provider
- `TELEGRAM_BOT_TOKEN` — get this from [@BotFather](https://t.me/BotFather) on Telegram

---

## Step 2: Add a Volume (important)

Without a volume, Mercury loses all memory and scheduled tasks on every redeploy.

1. In your Railway project canvas, right-click the **Mercury** service
2. Select **Attach Volume**
3. Set the mount path to `/data`
4. Click **Add**

Railway will redeploy automatically.

---

## Step 3: Pair Telegram

### Option A — No shell (recommended on Railway)

1. Get your numeric **Telegram user id** (e.g. message [@userinfobot](https://t.me/userinfobot) and copy `Id`).
2. In Railway → your Mercury service → **Variables**, add:
   - `TELEGRAM_BOOTSTRAP_ADMIN_ID` = that number (digits only)
3. Redeploy (or restart) the service once so the entrypoint can write `mercury.yaml`.
4. Open Telegram and message your bot with `/start`. You should be able to chat immediately.

After you are in, **remove** `TELEGRAM_BOOTSTRAP_ADMIN_ID` from Railway variables if you like (the admin is already stored on the volume; the variable is only used when there are zero Telegram admins).

**Adding more users (still no shell):** have them send `/start`. Existing Telegram **admins** get a DM with **Approve** / **Reject** buttons — tap Approve.

### Option B — Railway Shell (pairing code)

1. Message your bot with `/start`
2. The bot replies with a **pairing code** (six digits)
3. Railway → your service → **Deploy** → **Shell** (or local [Railway CLI](https://docs.railway.com/guides/cli): `railway shell`)
4. Run: `mercury telegram approve <pairing-code>`
5. You are the first admin.

If admins already exist and you must approve from the shell, use the numeric user id: `mercury telegram approve 123456789` (not a pairing code).

---

## Step 4: Talk to Mercury

Message your bot on Telegram. Mercury will respond with full tool access.

Some useful in-chat commands:

| Command | What it does |
|---|---|
| `/status` | Show agent config and budget |
| `/budget` | Check token usage |
| `/tools` | List all loaded tools |
| `/skills` | List installed skills |
| `/help` | Full manual |

---

## Step 5: Customize the Soul (optional)

Mercury's personality is defined by markdown files in `/data/mercury/soul/`.

To edit them, use the Railway shell:

```sh
# Edit soul.md directly
cat > /data/mercury/soul/soul.md << 'EOF'
You are Mercury. You work for [your name].
Your purpose is [what you want].
...
EOF
```

Or use a tool like [scp](https://linux.die.net/man/1/scp) or Railway's volume editor if available.

---

## Environment Variables Reference

All variables can be updated in Railway → your service → **Variables** tab. Mercury re-reads them on the next redeploy (the entrypoint script seeds `~/.mercury/.env` fresh on every container start).

See [README.md](./README.md#required-environment-variables) for the full list.

---

## Troubleshooting

**Mercury crashes on startup**
→ Check Railway logs. Usually means `TELEGRAM_BOT_TOKEN` is missing or invalid.

**Memory resets on redeploy**
→ You haven't attached a Volume at `/data`. Do Step 2.

**Bot doesn't respond**
→ Telegram pairing not done. Do Step 3.

**Token budget exhausted**
→ In Telegram, send `/budget reset` or `/budget set 100000`.

**Want to check logs**
→ Railway dashboard → your service → **Logs** tab. Or in shell: `mercury logs`.
