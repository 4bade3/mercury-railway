# ☿ Mercury — Railway Template

> Soul-driven AI agent with 31 built-in tools, Telegram access, skill system, and 24/7 daemon mode. One-click deploy on Railway.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/kJGxP-?referralCode=u71AUL&utm_medium=integration&utm_source=template&utm_campaign=generic)

---

## What is Mercury?

[Mercury](https://mercury.cosmicstack.org) is a persistent AI agent that runs 24/7 and is reachable via Telegram. It has:

- **31 built-in tools** — filesystem, shell, git, GitHub, web fetch, scheduler, memory
- **Soul system** — personality defined by markdown files you own (`soul.md`, `persona.md`, `taste.md`, `heartbeat.md`)
- **Token budgets** — daily enforcement with auto-concise mode
- **Skill system** — install community skills with a single command
- **Telegram** — HTML formatting, file uploads, typing indicators, multi-user access
- **Permission hardening** — shell blocklist, folder-level scoping, approval flows

This template deploys Mercury as a Railway worker service backed by a persistent Volume so your memory, schedules, skills, and soul files survive restarts.

---

## One-Click Deploy

Click the button above, or use this URL:

```
https://railway.com/new/template?template=https://github.com/4bade3/mercury-railway
```

Railway will prompt you to fill in the required environment variables before deploying.

---

## Required Environment Variables

| Variable | Description |
|---|---|
| `MERCURY_NAME` | Name for your agent (default: `Mercury`) |
| `MERCURY_OWNER` | Your name — the agent knows who it works for |
| `DEFAULT_PROVIDER` | LLM provider: `anthropic`, `openai`, `deepseek`, `grok` |
| `ANTHROPIC_API_KEY` | Your Anthropic API key (if using Anthropic) |
| `TELEGRAM_BOT_TOKEN` | Bot token from [@BotFather](https://t.me/BotFather) — required for headless use |

## Optional Environment Variables

| Variable | Default | Description |
|---|---|---|
| `OPENAI_API_KEY` | — | OpenAI key (GPT-4o, etc.) |
| `DEEPSEEK_API_KEY` | — | DeepSeek key (cost-effective default) |
| `GROK_API_KEY` | — | xAI Grok key |
| `ANTHROPIC_MODEL` | `claude-sonnet-4-20250514` | Override Anthropic model |
| `OPENAI_MODEL` | `gpt-4o-mini` | Override OpenAI model |
| `DAILY_TOKEN_BUDGET` | `50000` | Daily token budget |
| `HEARTBEAT_INTERVAL_MINUTES` | `60` | Heartbeat check interval |
| `GITHUB_TOKEN` | — | Fine-grained PAT for GitHub tools |
| `GITHUB_USERNAME` | — | Your GitHub username |
| `GITHUB_EMAIL` | — | Email for commit co-authoring |
| `GITHUB_DEFAULT_OWNER` | — | Default repo owner |
| `GITHUB_DEFAULT_REPO` | — | Default repo name |

---

## Architecture

```
Railway Service (Worker — no HTTP)
│
├── Dockerfile (Node 20 Alpine, multi-stage)
├── docker-entrypoint.sh
│   ├── Symlinks ~/.mercury → /data/mercury (Volume)
│   └── Seeds ~/.mercury/.env from Railway env vars
│
└── Mercury Agent (dist/index.js start)
    ├── Telegram bot (long polling via grammY)
    ├── Cron scheduler (persisted to /data/mercury/schedules.yaml)
    ├── Memory (JSONL in /data/mercury/memory/)
    └── Soul files (/data/mercury/soul/*.md)

Railway Volume mounted at /data
└── mercury/
    ├── mercury.yaml       # Agent config
    ├── .env               # Seeded from Railway vars on every start
    ├── soul/              # Personality markdown files
    ├── memory/            # Short-term, long-term, episodic
    ├── skills/            # Installed community skills
    ├── schedules.yaml     # Cron tasks
    └── permissions.yaml   # Tool scoping rules
```

---

## Setup After Deploy

### 1. Add a Volume

In your Railway project, right-click the Mercury service → **Attach Volume** → mount at `/data`.

> This is critical. Without the volume, all memory, schedules, and soul files reset on every redeploy.

### 2. Pair Telegram

1. Message [@BotFather](https://t.me/BotFather) on Telegram → `/newbot` → copy the token
2. Set `TELEGRAM_BOT_TOKEN` in Railway → redeploy
3. Message `/start` to your bot on Telegram
4. You'll receive a pairing code in the bot response
5. In Railway → your service → **Railway Shell** (or via logs), run:
   ```
   mercury telegram approve <your-pairing-code>
   ```
   Or approve directly via the Railway shell:
   ```sh
   node dist/index.js telegram approve <code>
   ```

### 3. Customize Your Soul

SSH into the Railway shell or edit files in your volume at `/data/mercury/soul/`:

- `soul.md` — core identity and values
- `persona.md` — communication style
- `taste.md` — aesthetic preferences
- `heartbeat.md` — what Mercury checks proactively

---

## Persistent Storage

All Mercury state lives in `/data/mercury/` (the Railway Volume):

| Path | Purpose |
|---|---|
| `mercury.yaml` | Main config |
| `.env` | API keys (written from Railway env vars) |
| `soul/*.md` | Agent personality |
| `permissions.yaml` | Tool scoping |
| `skills/` | Installed skills |
| `schedules.yaml` | Cron tasks |
| `memory/` | Short-term, long-term, episodic |

---

## How This Template Works

This repo is a thin deployment wrapper around the upstream [`cosmicstack-labs/mercury-agent`](https://github.com/cosmicstack-labs/mercury-agent) npm package. The `Dockerfile` installs Mercury from npm, and `docker-entrypoint.sh` handles:

1. Symlinking `~/.mercury` to the Railway Volume at `/data/mercury`
2. Writing a fresh `~/.mercury/.env` from Railway environment variables on every start
3. Creating required subdirectories on first boot

This means you always get the latest published Mercury version without needing to manually update the repo.

---

## Updating Mercury

Mercury is installed from npm at build time (`npm i -g @cosmicstack/mercury-agent`). To get a newer version, trigger a redeploy in Railway (or pin a version in the Dockerfile if you need stability).

---

## Providers

Mercury supports multiple LLM providers with automatic fallback:

| Provider | Env Key | Default Model |
|---|---|---|
| Anthropic | `ANTHROPIC_API_KEY` | `claude-sonnet-4-20250514` |
| OpenAI | `OPENAI_API_KEY` | `gpt-4o-mini` |
| DeepSeek | `DEEPSEEK_API_KEY` | `deepseek-chat` |
| Grok (xAI) | `GROK_API_KEY` | `grok-4` |

Set `DEFAULT_PROVIDER` to your preferred provider. Mercury tries providers in order and falls back automatically on failure.

---

## Links

- [Mercury website](https://mercury.cosmicstack.org)
- [Mercury GitHub](https://github.com/cosmicstack-labs/mercury-agent)
- [Mercury docs](https://mercury.cosmicstack.org/docs.html)
- [Report issues](https://github.com/cosmicstack-labs/mercury-agent/issues)

---

## License

MIT © [Cosmic Stack](https://github.com/cosmicstack-labs)
