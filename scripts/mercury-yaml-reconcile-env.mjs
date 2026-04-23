#!/usr/bin/env node
/**
 * Mercury loads config as deepMerge(getDefaultConfig(), mercury.yaml) — anything still
 * present on disk from an earlier run (doctor, setup, or older Mercury) overrides Railway
 * env vars. This script removes those overlays so injected env stays authoritative.
 *
 * Opt out (keep yaml as source of truth): set MERCURY_YAML_PREFER_DISK=true
 */
import fs from 'node:fs';
import { parse, stringify } from 'yaml';

const dataDir = process.env.MERCURY_DATA_DIR || '/data/mercury';
const yamlPath = `${dataDir}/mercury.yaml`;

if (process.env.MERCURY_YAML_PREFER_DISK === 'true') {
  console.log('mercury-railway: MERCURY_YAML_PREFER_DISK=true — skipping yaml/env reconcile.');
  process.exit(0);
}

if (!fs.existsSync(yamlPath)) {
  process.exit(0);
}

const raw = fs.readFileSync(yamlPath, 'utf8');
if (!raw.trim()) {
  process.exit(0);
}

let doc;
try {
  doc = parse(raw) || {};
} catch {
  console.error('mercury-railway: mercury.yaml parse failed; leaving file unchanged.');
  process.exit(0);
}

let changed = false;

// Whole block: env is the source for all provider keys + default.
if (doc.providers != null) {
  delete doc.providers;
  changed = true;
}

// Telegram: keep admins / members / pending; drop fields that mirror Railway env.
const tg = doc.channels?.telegram;
if (tg && typeof tg === 'object') {
  for (const k of ['botToken', 'enabled', 'streaming', 'webhookUrl', 'allowedChatIds']) {
    if (k in tg) {
      delete tg[k];
      changed = true;
    }
  }
}

// GitHub + runtime paths/budgets: map to GITHUB_* / MEMORY_DIR / DAILY_* / HEARTBEAT_* env.
for (const k of ['github', 'memory', 'tokens', 'heartbeat']) {
  if (doc[k] != null) {
    delete doc[k];
    changed = true;
  }
}

// Identity: always align with current Railway vars when set (seed only runs on empty owner).
if (process.env.MERCURY_OWNER?.trim()) {
  doc.identity = doc.identity ?? {};
  const nextOwner = process.env.MERCURY_OWNER.trim();
  if (doc.identity.owner !== nextOwner) {
    doc.identity.owner = nextOwner;
    changed = true;
  }
}
if (process.env.MERCURY_NAME?.trim()) {
  doc.identity = doc.identity ?? {};
  const nextName = process.env.MERCURY_NAME.trim();
  if (doc.identity.name !== nextName) {
    doc.identity.name = nextName;
    changed = true;
  }
}

if (!changed) {
  console.log('mercury-railway: mercury.yaml already aligned with env (no changes).');
  process.exit(0);
}

fs.writeFileSync(yamlPath, stringify(doc), 'utf8');
console.log('mercury-railway: Updated mercury.yaml so Railway env vars are not overridden by stale yaml.');
