# ── Mercury Agent — Railway Template ─────────────────────
# Pulls the latest @cosmicstack/mercury-agent from npm.
# All persistent state goes to /data/mercury (Railway Volume).
# ─────────────────────────────────────────────────────────
FROM node:20-alpine

WORKDIR /app

# Pin a specific version for reproducibility, or use "latest"
ARG MERCURY_VERSION=latest

# Install Mercury globally from npm
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
