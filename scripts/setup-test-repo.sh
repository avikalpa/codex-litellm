#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: scripts/setup-test-repo.sh [--refresh] <fixture> [dest]

Fixtures:
  calibre-web   shallow clone of janeczku/calibre-web
  mini-web      local static web fixture with buttons and CSS
  python-cli    local Python CLI fixture with README and tests
EOF
}

refresh=0
if [[ "${1:-}" == "--refresh" ]]; then
  refresh=1
  shift
fi

fixture="${1:-}"
dest="${2:-test-workspace}"

if [[ -z "$fixture" ]]; then
  usage
  exit 1
fi

if [[ "${PRUNE_TEST_WORKSPACES:-1}" != "0" ]]; then
  "$repo_root/scripts/prune-test-workspaces.sh" "$dest"
fi

make_git_fixture_repo() {
  local repo_dir="$1"
  git -C "$repo_dir" init -q
  git -C "$repo_dir" config user.name "codex-litellm-fixture"
  git -C "$repo_dir" config user.email "fixtures@codex-litellm.local"
  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -q -m "fixture baseline"
}

reset_dest() {
  local repo_dir="$1"
  if [[ -e "$repo_dir" && "$refresh" -eq 1 ]]; then
    rm -rf "$repo_dir"
  fi
}

setup_calibre_web() {
  local repo_dir="$1"
  reset_dest "$repo_dir"

  if [[ -d "$repo_dir/.git" ]]; then
    echo "Test workspace already exists. Pulling latest changes..."
    git -C "$repo_dir" pull --ff-only
    return
  fi

  echo "Cloning calibre-web fixture..."
  git clone --depth=1 https://github.com/janeczku/calibre-web.git "$repo_dir"
}

setup_mini_web() {
  local repo_dir="$1"
  reset_dest "$repo_dir"
  mkdir -p "$repo_dir"

  cat >"$repo_dir/index.html" <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Fixture Web App</title>
    <link rel="stylesheet" href="styles.css">
  </head>
  <body>
    <main class="page">
      <header class="hero">
        <p class="eyebrow">codex-litellm fixture</p>
        <h1>Workspace Controls</h1>
        <p>Small static app used for agentic UI-edit smoke tests.</p>
      </header>

      <section class="panel">
        <h2>Primary Actions</h2>
        <div class="button-row">
          <button class="btn btn-primary">Deploy</button>
          <button class="btn btn-secondary">Preview</button>
          <button class="btn">Save Draft</button>
        </div>
      </section>

      <section class="panel">
        <h2>Settings</h2>
        <form class="settings-form">
          <label>
            Team name
            <input type="text" value="Agents">
          </label>
          <div class="button-row">
            <input type="submit" value="Update Settings">
            <input type="button" value="Invite Teammate">
          </div>
        </form>
      </section>
    </main>
    <script src="app.js"></script>
  </body>
</html>
EOF

  cat >"$repo_dir/styles.css" <<'EOF'
:root {
  color-scheme: light;
  --bg: #f3efe6;
  --panel: #fffaf2;
  --text: #1f2a2c;
  --muted: #69767a;
  --border: #d7cabb;
  --primary: #195c53;
  --secondary: #d17a2d;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: Georgia, "Times New Roman", serif;
  background: linear-gradient(180deg, #f6f1e7 0%, #efe3d0 100%);
  color: var(--text);
}

.page {
  width: min(920px, calc(100% - 32px));
  margin: 48px auto;
}

.hero,
.panel {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 20px;
  padding: 24px;
  box-shadow: 0 12px 30px rgba(31, 42, 44, 0.08);
}

.panel + .panel {
  margin-top: 20px;
}

.eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--muted);
  font-size: 12px;
}

.button-row {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 12px;
}

.btn,
button,
input[type="submit"],
input[type="button"] {
  border: 1px solid transparent;
  background: #f2ebe1;
  color: var(--text);
  padding: 12px 18px;
  border-radius: 12px;
  cursor: pointer;
  transition: transform 160ms ease, box-shadow 160ms ease, background 160ms ease;
}

.btn-primary {
  background: var(--primary);
  color: #fff;
}

.btn-secondary {
  background: var(--secondary);
  color: #fff;
}

.btn:hover,
button:hover,
input[type="submit"]:hover,
input[type="button"]:hover {
  transform: translateY(-1px);
  box-shadow: 0 8px 18px rgba(31, 42, 44, 0.12);
}

.settings-form label {
  display: block;
  margin-top: 12px;
}

.settings-form input[type="text"] {
  width: 100%;
  margin-top: 8px;
  padding: 12px 14px;
  border-radius: 12px;
  border: 1px solid var(--border);
}
EOF

  cat >"$repo_dir/app.js" <<'EOF'
document.querySelectorAll(".btn").forEach((button) => {
  button.addEventListener("click", () => {
    button.dataset.clicked = "true";
  });
});
EOF

  cat >"$repo_dir/README.md" <<'EOF'
# Fixture Web App

Static UI fixture for codex-litellm model tests.

- stack: plain HTML, CSS, JS
- purpose: verify repo inspection, button styling edits, and clean finalization
EOF

  make_git_fixture_repo "$repo_dir"
}

setup_python_cli() {
  local repo_dir="$1"
  reset_dest "$repo_dir"
  mkdir -p "$repo_dir/src/fixture_cli" "$repo_dir/tests"

  cat >"$repo_dir/pyproject.toml" <<'EOF'
[build-system]
requires = ["setuptools>=69"]
build-backend = "setuptools.build_meta"

[project]
name = "fixture-cli"
version = "0.1.0"
description = "Small Python CLI fixture for codex-litellm tests"
requires-python = ">=3.11"

[project.scripts]
fixture-cli = "fixture_cli.cli:main"
EOF

  cat >"$repo_dir/src/fixture_cli/__init__.py" <<'EOF'
__all__ = ["main"]
EOF

  cat >"$repo_dir/src/fixture_cli/cli.py" <<'EOF'
import argparse


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Fixture CLI")
    parser.add_argument("name", help="Name to greet")
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    print(f"hello, {args.name}")


if __name__ == "__main__":
    main()
EOF

  cat >"$repo_dir/tests/test_cli.py" <<'EOF'
from fixture_cli.cli import build_parser


def test_parser_accepts_name() -> None:
    args = build_parser().parse_args(["world"])
    assert args.name == "world"
EOF

  cat >"$repo_dir/README.md" <<'EOF'
# Fixture CLI

Small Python CLI fixture for codex-litellm model tests.

## Usage

```bash
fixture-cli world
```
EOF

  make_git_fixture_repo "$repo_dir"
}

case "$fixture" in
  calibre-web)
    setup_calibre_web "$dest"
    ;;
  mini-web)
    setup_mini_web "$dest"
    ;;
  python-cli)
    setup_python_cli "$dest"
    ;;
  *)
    echo "Unknown fixture: $fixture" >&2
    usage
    exit 1
    ;;
esac

echo "Test environment is ready in '$dest' using fixture '$fixture'."
