#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const TARGET_SUFFIX = new Map([
  ['linux:x64', 'linux-x64'],
  ['linux:arm64', 'linux-arm64'],
  ['android:arm64', 'android-arm64'],
  ['darwin:x64', 'macos-x64'],
  ['darwin:arm64', 'macos-arm64'],
  ['win32:x64', 'windows-x64'],
  ['win32:arm64', 'windows-arm64'],
  ['freebsd:x64', 'freebsd-x64'],
]);

const key = `${process.platform}:${process.arch}`;
const suffix = TARGET_SUFFIX.get(key);

if (!suffix) {
  console.error(`codex-litellm: unsupported platform/arch combination: ${process.platform}/${process.arch}`);
  process.exit(1);
}

const binaryName = process.platform === 'win32' ? 'codex-litellm.exe' : 'codex-litellm';
const binary = path.join(__dirname, '..', 'dist', suffix, binaryName);

if (!fs.existsSync(binary)) {
  console.error('codex-litellm: compiled binary not found. Did the install step complete successfully?');
  console.error(`Expected at: ${binary}`);
  console.error('Reinstall with `npm install -g @avikalpa/codex-litellm` or build locally using ./build.sh');
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
