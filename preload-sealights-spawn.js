'use strict';

/**
 * Distroless-safe pattern: spawn the Node binary with an argv array (no shell).
 */
const path = require('path');
const { spawnSync } = require('child_process');

const appJs = path.resolve(__dirname, 'app.js');
const cliJs = path.resolve(__dirname, 'fake-sl-cli.js');

function main() {
  const sealightsArgs = [
    cliJs,
    'run',
    '--tokenFile',
    'sltoken.txt',
    '--buildSessionIdFile',
    'buildSessionId',
    '--',
    appJs,
  ];
  console.log('[preload-spawn] Sealights-style re-exec via spawnSync (no shell)...');

  const r = spawnSync(process.execPath, sealightsArgs, { stdio: 'inherit', cwd: __dirname });
  if (r.error) {
    console.error('[preload-spawn] Sealights spawn error:', r.error.message);
  } else if (r.signal) {
    console.error('[preload-spawn] Sealights killed by signal:', r.signal);
    process.exit(1);
  } else if (r.status === 0) {
    process.exit(0);
  } else {
    console.error('[preload-spawn] Sealights path failed with exit', r.status);
  }

  const fb = spawnSync(process.execPath, [appJs], { stdio: 'inherit', cwd: __dirname });
  if (fb.error) {
    console.error('[preload-spawn] Fallback failed:', fb.error.message);
    process.exit(1);
  }
  if (fb.signal) {
    process.exit(1);
  }
  process.exit(fb.status === null ? 1 : fb.status);
}

main();
