#!/usr/bin/env node
const crypto = require('crypto');
const fs = require('fs');
const { mkdirSync, rmSync } = fs;
const path = require('path');
const os = require('os');
const https = require('https');
const { execFileSync } = require('child_process');

const SUPPORTED = {
  'linux:x64': 'linux-x64',
  'android:arm64': 'android-arm64'
};

if (process.env.CODEX_LITELLM_SKIP_DOWNLOAD === '1') {
  console.log('Skipping codex-litellm binary download.');
  process.exit(0);
}

const key = `${process.platform}:${process.arch}`;
const suffix = SUPPORTED[key];

if (!suffix) {
  console.error(`codex-litellm: no prebuilt binary for ${process.platform}/${process.arch}.`);
  console.error('Please build from source instead: https://github.com/avikalpa/codex-litellm');
  process.exit(0);
}

const pkg = require('../package.json');
const version = pkg.version;
const tag = `v${version}`;
const baseUrl = `https://github.com/avikalpa/codex-litellm/releases/download/${tag}`;
const archiveName = `codex-litellm-${suffix}.tar.gz`;
const archiveUrl = `${baseUrl}/${archiveName}`;
const checksumUrl = `${archiveUrl}.sha256`;

const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'codex-litellm-'));
const archivePath = path.join(tmpDir, archiveName);
const checksumPath = `${archivePath}.sha256`;

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    const request = https.get(url, (res) => {
      if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        file.close(() => fs.unlink(dest, () => {}));
        download(res.headers.location, dest).then(resolve).catch(reject);
        res.resume();
        return;
      }

      if (res.statusCode !== 200) {
        reject(new Error(`Request failed. Status code: ${res.statusCode} for ${url}`));
        res.resume();
        return;
      }

      res.pipe(file);
    });

    request.on('error', (err) => {
      reject(err);
    });
    file.on('finish', () => file.close(resolve));
    file.on('error', (err) => reject(err));
  });
}

function verifyChecksum(filePath, checksumFile) {
  const expected = fs.readFileSync(checksumFile, 'utf8').split(' ')[0].trim();
  const hash = crypto.createHash('sha256');
  const data = fs.readFileSync(filePath);
  hash.update(data);
  const actual = hash.digest('hex');
  if (expected !== actual) {
    throw new Error(`Checksum mismatch: expected ${expected}, got ${actual}`);
  }
}

(async () => {
  try {
    console.log(`Downloading ${archiveName} (${version})...`);
    await download(archiveUrl, archivePath);

    console.log('Downloading checksum...');
    await download(checksumUrl, checksumPath);

    verifyChecksum(archivePath, checksumPath);

    const distRoot = path.join(__dirname, '..', 'dist');
    const destDir = path.join(distRoot, suffix);

    rmSync(destDir, { recursive: true, force: true });
    mkdirSync(destDir, { recursive: true });

    console.log('Extracting binary...');
    execFileSync('tar', ['-xzf', archivePath, '-C', destDir]);

    const binaryPath = path.join(destDir, 'codex-litellm');
    fs.chmodSync(binaryPath, 0o755);

    console.log(`codex-litellm binary installed for ${suffix}.`);
  } catch (err) {
    console.error(`Failed to install codex-litellm prebuilt binary: ${err.message}`);
    console.error('You can build manually by running `npm explore @avikalpa/codex-litellm -- ./build.sh`.');
    process.exit(1);
  }
})();
