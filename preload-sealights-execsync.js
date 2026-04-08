'use strict';

/**
 * Simulates preload-sealights.js v0.0.3 behavior: re-invokes the app through a
 * "Sealights CLI" using execSync(). execSync() delegates to /bin/sh -c, which
 * fails on distroless images (ENOENT).
 */
const path = require('path');
const { execSync } = require('child_process');

const appJs = path.resolve(__dirname, 'app.js');
const cliJs = path.resolve(__dirname, 'fake-sl-cli.js');

function main() {
  const sealightsCmd = `${process.execPath} ${cliJs} run --tokenFile sltoken.txt --buildSessionIdFile buildSessionId -- ${appJs}`;
  console.log('[preload-execsync] Sealights-style re-exec via execSync (requires /bin/sh)...');

  try {
    execSync(sealightsCmd, { stdio: 'inherit', cwd: __dirname });
    process.exit(0);
  } catch (e) {
    console.error('[preload-execsync] Sealights path failed:', e.message);
    try {
      execSync(`${process.execPath} ${appJs}`, { stdio: 'inherit', cwd: __dirname });
      process.exit(0);
    } catch (e2) {
      console.error('[preload-execsync] Fallback failed:', e2.message);
      process.exit(1);
    }
  }
}

main();
