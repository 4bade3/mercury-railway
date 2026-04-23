# ── Mercury Agent — Railway Template ─────────────────────
# Pulls the latest @cosmicstack/mercury-agent from npm.
# All persistent state goes to /data/mercury (Railway Volume).
# ─────────────────────────────────────────────────────────
FROM node:20-alpine

WORKDIR /opt/mercury-railway-bootstrap
COPY scripts/package.json package.json
COPY scripts/mercury-yaml-seed.mjs scripts/telegram-bootstrap.mjs ./
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

# Start Mercury in foreground (Railway keeps the container alive)
CMD ["mercury", "start"]
