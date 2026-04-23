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
https://railway.com/deploy/kJGxP-?referralCode=u71AUL&utm_medium=integration&utm_source=template&utm_campaign=generic
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

## Pinning the Mercury npm package (recommended on Railway)

The Docker image installs `@cosmicstack/mercury-agent` at **build** time (`Dockerfile` `ARG MERCURY_VERSION`, default `latest`). To pin **without** rebuilding from git, set a Railway **Variable** (runtime env):

| Variable | Description |
|---|---|
| **`MERCURY_AGENT_VERSION`** | npm dist-tag or semver, e.g. `0.5.2`, `0.5.4`, or `latest`. On each container start the entrypoint runs `npm install -g @cosmicstack/mercury-agent@<value>` before `mercury start`. Requires outbound network on boot. |
| **`MERCURY_VERSION`** | Alias for `MERCURY_AGENT_VERSION` if the latter is unset. |

If **both are unset**, the globally installed version from the image (last `docker build`) is used—no extra install on start.

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
| `TELEGRAM_BOOTSTRAP_ADMIN_ID` | — | **CLI-less pairing:** your numeric Telegram user id; seeds the first admin on boot when `mercury.yaml` has no Telegram admins yet ([details below](#telegram-without-a-shell)) |

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
3. **Without a shell:** set `TELEGRAM_BOOTSTRAP_ADMIN_ID` to your numeric Telegram user id (e.g. from [@userinfobot](https://t.me/userinfobot)), redeploy once, then message `/start` to your bot. See [Telegram without a shell](#telegram-without-a-shell).
4. **With Railway Shell:** message `/start`, copy the six-digit pairing code, then in **Deploy → Shell** run `mercury telegram approve <code>`.

### 3. Customize Your Soul

SSH into the Railway shell or edit files in your volume at `/data/mercury/soul/`:

- `soul.md` — core identity and values
- `persona.md` — communication style
- `taste.md` — aesthetic preferences
- `heartbeat.md` — what Mercury checks proactively

---

## Headless setup (no interactive wizard)

Mercury only skips the setup wizard when **`mercury.yaml` exists** and **`identity.owner`** is non-empty. On a fresh volume that file does not exist, so `mercury start` prints `First run detected` and waits for `Your name:` — which never works on Railway.

This template’s entrypoint runs **`mercury-yaml-seed.mjs`** before starting Mercury: it creates or updates `mercury.yaml` with **`MERCURY_OWNER`** (and **`MERCURY_NAME`** if set) from your environment. Set **`MERCURY_OWNER`** in Railway on every deploy; if the variable is missing, the container exits with an error instead of hanging.

---

## Telegram without a shell

Mercury’s first admin is normally approved with `mercury telegram approve` in a terminal. This template adds **`TELEGRAM_BOOTSTRAP_ADMIN_ID`**: set it in Railway to your **numeric Telegram user id** (e.g. from [@userinfobot](https://t.me/userinfobot)). On each container start, a small bootstrap step runs **only while `mercury.yaml` has zero Telegram admins** and writes that user as the first admin (same id is used as `chatId`, which matches private chats with a bot).

The entrypoint also sets **`TELEGRAM_ENABLED=true`** whenever **`TELEGRAM_BOT_TOKEN`** is set, so Telegram actually starts in headless Railway (Mercury’s default would keep Telegram off).

**More users:** no shell — when someone new sends `/start`, existing Telegram admins receive inline **Approve** / **Reject** buttons.

**Security:** anyone who can edit your Railway variables can pick the bootstrap id. Remove `TELEGRAM_BOOTSTRAP_ADMIN_ID` after the first successful pairing if you want to avoid leaving it set.

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

**Railway:** do not set a **custom start command** that runs `mercury start` alone — that bypasses the image `ENTRYPOINT` (`docker-entrypoint.sh`), so the volume symlink, `.env` seeding, and YAML/Telegram bootstrap never run. Leave the deploy start command empty and use the Dockerfile `CMD` (see `railway.toml`).

---

## Test locally with Docker

Put the variables you need in a **`.env`** file at the repo root (same names as [Required Environment Variables](#required-environment-variables) and Railway). That file is gitignored — do not commit it.

From the repo root:

```bash
docker build -t mercury-railway:local .
mkdir -p ./mercury-local-data
docker run --rm -it \
  -v "$(pwd)/mercury-local-data:/data/mercury" \
  --env-file ./.env \
  mercury-railway:local
```

- **`MERCURY_OWNER`** must be set in `.env`; otherwise the entrypoint exits before Mercury starts.
- **`TELEGRAM_BOOTSTRAP_ADMIN_ID`** in `.env` is optional; omit it if you will pair with `mercury telegram approve` inside the container (second terminal: `docker exec -it <container_id> sh` → `mercury telegram approve <code>`).
- Mount **`-v ...:/data/mercury`** so `mercury.yaml`, memory, and Telegram state survive between runs (like a Railway volume). Omit the mount for a throwaway run.

Detached run: add **`-d`**, then **`docker logs -f <container_id>`** to follow output.

---

## Updating Mercury

- **Pinned in Railway:** set `MERCURY_AGENT_VERSION` (e.g. bump `0.5.2` → `0.5.4`) and redeploy; the entrypoint installs that release on container start.
- **Image default only:** leave `MERCURY_AGENT_VERSION` / `MERCURY_VERSION` unset; change the baked version by editing the Dockerfile `ARG MERCURY_VERSION` and rebuilding, or trigger a Railway rebuild to refresh `latest` at build time.

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
