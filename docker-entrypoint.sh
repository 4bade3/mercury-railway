#!/bin/sh
set -e

MERCURY_DIR="${MERCURY_DATA_DIR:-/data/mercury}"
HOME_MERCURY="$HOME/.mercury"

# ── Ensure persistent data dir exists ────────────────────
mkdir -p "$MERCURY_DIR"

# ── Symlink ~/.mercury → /data/mercury ───────────────────
if [ ! -L "$HOME_MERCURY" ]; then
  if [ -d "$HOME_MERCURY" ]; then
    # Merge existing dir into persistent volume, then replace with symlink
    cp -rn "$HOME_MERCURY/." "$MERCURY_DIR/" 2>/dev/null || true
    rm -rf "$HOME_MERCURY"
  fi
  ln -s "$MERCURY_DIR" "$HOME_MERCURY"
fi

# ── Sub-directories Mercury expects ──────────────────────
mkdir -p \
  "$MERCURY_DIR/soul" \
  "$MERCURY_DIR/memory" \
  "$MERCURY_DIR/skills"

# ── Seed .env from Railway environment variables ─────────
# Mercury reads ~/.mercury/.env at startup.
# We write it fresh on every container start so Railway vars always win.
ENV_FILE="$MERCURY_DIR/.env"

write_env() {
  local key="$1"
  local val="$2"
  if [ -n "$val" ]; then
    # Remove existing line for this key, then append
    if [ -f "$ENV_FILE" ]; then
      grep -v "^${key}=" "$ENV_FILE" > "${ENV_FILE}.tmp" && mv "${ENV_FILE}.tmp" "$ENV_FILE" || true
    fi
    echo "${key}=${val}" >> "$ENV_FILE"
  fi
}

touch "$ENV_FILE"

write_env "MERCURY_NAME"           "${MERCURY_NAME:-Mercury}"
write_env "MERCURY_OWNER"          "${MERCURY_OWNER:-}"
write_env "DEFAULT_PROVIDER"       "${DEFAULT_PROVIDER:-anthropic}"

write_env "ANTHROPIC_API_KEY"      "${ANTHROPIC_API_KEY:-}"
write_env "ANTHROPIC_MODEL"        "${ANTHROPIC_MODEL:-claude-sonnet-4-20250514}"

write_env "OPENAI_API_KEY"         "${OPENAI_API_KEY:-}"
write_env "OPENAI_BASE_URL"        "${OPENAI_BASE_URL:-https://api.openai.com/v1}"
write_env "OPENAI_MODEL"           "${OPENAI_MODEL:-gpt-4o-mini}"

write_env "DEEPSEEK_API_KEY"       "${DEEPSEEK_API_KEY:-}"
write_env "DEEPSEEK_BASE_URL"      "${DEEPSEEK_BASE_URL:-https://api.deepseek.com/v1}"
write_env "DEEPSEEK_MODEL"         "${DEEPSEEK_MODEL:-deepseek-chat}"

write_env "GROK_API_KEY"           "${GROK_API_KEY:-}"
write_env "GROK_BASE_URL"          "${GROK_BASE_URL:-https://api.x.ai/v1}"
write_env "GROK_MODEL"             "${GROK_MODEL:-grok-4}"

write_env "OLLAMA_LOCAL_ENABLED"   "${OLLAMA_LOCAL_ENABLED:-false}"

write_env "TELEGRAM_BOT_TOKEN"     "${TELEGRAM_BOT_TOKEN:-}"
# Mercury defaults TELEGRAM_ENABLED=false; turn Telegram on when a token is set (Railway is headless).
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  write_env "TELEGRAM_ENABLED" "true"
fi

write_env "DAILY_TOKEN_BUDGET"     "${DAILY_TOKEN_BUDGET:-50000}"
write_env "HEARTBEAT_INTERVAL_MINUTES" "${HEARTBEAT_INTERVAL_MINUTES:-60}"

write_env "GITHUB_TOKEN"           "${GITHUB_TOKEN:-}"
write_env "GITHUB_USERNAME"        "${GITHUB_USERNAME:-}"
write_env "GITHUB_EMAIL"           "${GITHUB_EMAIL:-}"
write_env "GITHUB_DEFAULT_OWNER"   "${GITHUB_DEFAULT_OWNER:-}"
write_env "GITHUB_DEFAULT_REPO"    "${GITHUB_DEFAULT_REPO:-}"

write_env "MEMORY_DIR"             "${MEMORY_DIR:-/data/mercury/memory}"

echo "☿  Mercury entrypoint: data dir ready at $MERCURY_DIR"
echo "☿  Provider: ${DEFAULT_PROVIDER:-anthropic}"

# Mercury requires mercury.yaml + identity.owner or it opens the interactive wizard (hangs without TTY).
node /opt/mercury-railway-bootstrap/mercury-yaml-seed.mjs

# Mercury merges mercury.yaml ON TOP OF env defaults — old yaml keeps first-run API keys, models,
# Telegram token, etc. Strip those overlays each boot so Railway Variables stay authoritative.
node /opt/mercury-railway-bootstrap/mercury-yaml-reconcile-env.mjs

# Optional CLI-less first Telegram admin (numeric user id, e.g. from @userinfobot).
if [ -n "${TELEGRAM_BOOTSTRAP_ADMIN_ID:-}" ]; then
  node /opt/mercury-railway-bootstrap/telegram-bootstrap.mjs
fi

# Optional: pin @cosmicstack/mercury-agent from Railway Variables (runtime, needs npm registry).
# MERCURY_AGENT_VERSION wins; MERCURY_VERSION is an alias. Examples: 0.5.2 | latest
# Leave both unset to use whatever the image installed at build time (Dockerfile ARG MERCURY_VERSION).
MERCURY_PIN="${MERCURY_AGENT_VERSION:-${MERCURY_VERSION:-}}"
if [ -n "$MERCURY_PIN" ]; then
  echo "☿  Installing @cosmicstack/mercury-agent@${MERCURY_PIN} (runtime pin from env)..."
  npm install -g --omit=dev "@cosmicstack/mercury-agent@${MERCURY_PIN}"
fi

echo "☿  Starting agent..."

exec "$@"
