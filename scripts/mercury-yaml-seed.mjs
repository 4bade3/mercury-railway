#!/usr/bin/env node
/**
 * Mercury treats setup as incomplete until ~/.mercury/mercury.yaml exists with a non-empty
 * identity.owner — otherwise `mercury start` runs the interactive wizard (no TTY on Railway).
 * This script seeds that from MERCURY_OWNER / MERCURY_NAME when missing.
 */
import fs from 'node:fs';
import { parse, stringify } from 'yaml';

const dataDir = process.env.MERCURY_DATA_DIR || '/data/mercury';
const yamlPath = `${dataDir}/mercury.yaml`;
const owner = process.env.MERCURY_OWNER?.trim();
const name = process.env.MERCURY_NAME?.trim() || 'Mercury';

if (!owner) {
  console.error(
    'mercury-railway: MERCURY_OWNER is not set. Set it in Railway Variables so setup can finish without a TTY.',
  );
  process.exit(1);
}

let doc = {};
if (fs.existsSync(yamlPath)) {
  const raw = fs.readFileSync(yamlPath, 'utf8');
  if (raw.trim()) doc = parse(raw) || {};
}

doc.identity = doc.identity ?? {};
const currentOwner = String(doc.identity.owner ?? '').trim();
if (currentOwner.length > 0) {
  console.log('mercury-railway: mercury.yaml already has identity.owner — seed skipped.');
  process.exit(0);
}

doc.identity.owner = owner;
if (!String(doc.identity.name ?? '').trim()) {
  doc.identity.name = name;
}

fs.mkdirSync(dataDir, { recursive: true });
fs.writeFileSync(yamlPath, stringify(doc), 'utf8');
console.log(`mercury-railway: Seeded mercury.yaml identity for headless deploy (${owner}).`);
