#!/usr/bin/env node
'use strict';

/**
 * Minimal stand-in for slnodejs CLI: `node fake-sl-cli.js run ... -- <entry.js>`
 * Uses spawnSync (no shell) so this file stays valid in distroless.
 */
const { spawnSync } = require('child_process');

const argv = process.argv.slice(2);
const sep = argv.indexOf('--');
if (sep === -1 || !argv[sep + 1]) {
  console.error('usage: node fake-sl-cli.js run ... -- <script.js>');
  process.exit(1);
}

const script = argv[sep + 1];
const r = spawnSync(process.execPath, [script], { stdio: 'inherit' });
if (r.error) {
  console.error(r.error);
  process.exit(1);
}
process.exit(r.status === null ? 1 : r.status);
