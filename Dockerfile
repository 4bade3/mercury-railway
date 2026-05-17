# ── Mercury Agent — Railway Template ─────────────────────
# Pulls the latest @cosmicstack/mercury-agent from npm.
# All persistent state goes to /data/mercury (Railway Volume).
# ─────────────────────────────────────────────────────────
FROM node:20-alpine

WORKDIR /opt/mercury-railway-bootstrap
COPY scripts/package.json package.json
COPY scripts/mercury-yaml-seed.mjs scripts/mercury-yaml-reconcile-env.mjs scripts/telegram-bootstrap.mjs ./
RUN npm install --omit=dev

WORKDIR /app

# Default npm version baked into the image. Override at **runtime** with Railway Variables
# MERCURY_AGENT_VERSION or MERCURY_VERSION (see docker-entrypoint.sh), or pass --build-arg at build.
ARG MERCURY_VERSION=latest
RUN npm install -g @cosmicstack/mercury-agent@${MERCURY_VERSION}

# Mercury data dir — mount a Railway Volume at /data
ENV MERCURY_DATA_DIR=/data/mercury
ENV HOME=/root

# Entrypoint wires ~/.mercury → /data/mercury and seeds .env from Railway vars
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

# Start Mercury attached to the container so Railway can keep PID 1 alive and
# stream stdout/stderr.
#   - `mercury start` (default)    → forks a detached daemon and exits the parent
#                                    (Railway sees PID 1 die → container restarts;
#                                    daemon logs go to ~/.mercury/daemon.log,
#                                    which is invisible to Railway).
#   - `mercury start --foreground` → starts the Ink/React TUI, which calls
#                                    setRawMode() on stdin and crashes with
#                                    "Raw mode is not supported" on a Railway
#                                    worker (no TTY).
#   - `mercury start --daemon`     → runs the agent in the CURRENT process with
#                                    a watchdog, no TUI, pino logs to stderr.
#                                    Despite the "internal" label in --help,
#                                    this is the correct headless mode.
# Verbose is required because pino defaults to `silent` unless LOG_LEVEL is set.
ENV LOG_LEVEL=info
CMD ["mercury", "start", "--daemon"]
