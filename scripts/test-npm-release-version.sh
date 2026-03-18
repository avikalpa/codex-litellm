#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

base_version=$(node -p "require('./package.json').codexLitellm.baseVersion")
upstream_commit=$(node -p "require('./package.json').codexLitellm.upstreamCommit")
lit_commit=$(git rev-parse --short HEAD)
release_tag="${RELEASE_TAG:-v${base_version}+${upstream_commit}+lit${lit_commit}}"

if [[ ! "$release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+\+[0-9a-f]{8}\+lit[0-9a-f]{7,}$ ]]; then
  echo "release tag format is invalid: ${release_tag}" >&2
  exit 1
fi

npm_version="${release_tag#v}"
npm_version="${npm_version//+/-}"

if [[ ! "$npm_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-[0-9a-f]{8}-lit[0-9a-f]{7,}$ ]]; then
  echo "derived npm version format is invalid: ${npm_version}" >&2
  exit 1
fi

expected_prefix="${base_version}-${upstream_commit}-lit"
if [[ "$npm_version" != "${expected_prefix}"* ]]; then
  echo "derived npm version does not match package metadata: ${npm_version}" >&2
  exit 1
fi

echo "npm release version OK: ${release_tag} -> ${npm_version}"
