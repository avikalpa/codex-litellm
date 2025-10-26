#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const SUPPORTED = {
  'linux:x64': 'linux-x64',
  'android:arm64': 'android-arm64'
};

const key = `${process.platform}:${process.arch}`;
const suffix = SUPPORTED[key];

if (!suffix) {
  console.error(`codex-litellm: unsupported platform/arch combination: ${process.platform}/${process.arch}`);
  process.exit(1);
}

const binary = path.join(__dirname, '..', 'dist', suffix, 'codex-litellm');
if (!fs.existsSync(binary)) {
  console.error('codex-litellm: compiled binary not found. Did the install step complete successfully?');
  console.error(`Expected at: ${binary}`);
  process.exit(1);
}

const child = spawn(binary, process.argv.slice(2), { stdio: 'inherit' });
child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exit(code);
  }
});
