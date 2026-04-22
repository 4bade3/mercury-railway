#!/usr/bin/env node
/**
 * CLI-less first Telegram admin: if TELEGRAM_BOOTSTRAP_ADMIN_ID is set and
 * mercury.yaml has no Telegram admins yet, add that numeric user id as admin.
 * Private chat id === user id for Telegram bots.
 */
import fs from 'node:fs';
import { parse, stringify } from 'yaml';

const dataDir = process.env.MERCURY_DATA_DIR || '/data/mercury';
const yamlPath = `${dataDir}/mercury.yaml`;
const rawId = process.env.TELEGRAM_BOOTSTRAP_ADMIN_ID?.trim();

if (!rawId) {
  process.exit(0);
}

const userId = Number(rawId);
if (!Number.isInteger(userId) || userId <= 0) {
  console.error('mercury-railway: TELEGRAM_BOOTSTRAP_ADMIN_ID must be a positive integer (your Telegram user id).');
  process.exit(1);
}

let doc = {};
if (fs.existsSync(yamlPath)) {
  const raw = fs.readFileSync(yamlPath, 'utf8');
  doc = raw.trim() ? parse(raw) || {} : {};
}

doc.channels = doc.channels ?? {};
doc.channels.telegram = doc.channels.telegram ?? {};
const tg = doc.channels.telegram;
const admins = tg.admins ?? [];

if (admins.length > 0) {
  console.log('mercury-railway: Telegram already has admins — bootstrap skipped.');
  process.exit(0);
}

const approvedAt = new Date().toISOString();
tg.admins = [{ userId, chatId: userId, approvedAt }];
tg.members = tg.members ?? [];
tg.pending = (tg.pending ?? []).filter((p) => Number(p.userId) !== userId);
tg.enabled = true;

fs.mkdirSync(dataDir, { recursive: true });
fs.writeFileSync(yamlPath, stringify(doc), 'utf8');
console.log(`mercury-railway: Bootstrapped first Telegram admin (user id ${userId}).`);
