# codex‑litellm

> **An unofficial, Apache‑2.0‑licensed patch set and distribution of the OpenAI Codex CLI** with native LiteLLM support, multi‑layer caching, and production‑grade observability.
>
> *Upstream base: `openai/codex` (Apache‑2.0). This project maintains a reproducible patch on top and ships binaries for convenience.*

---

## Highlights

* **Direct LiteLLM Integration** – Talk to LiteLLM backends natively; no extra proxy needed
* **LiteLLM‑side Caching Support** – Plays nicely with LiteLLM’s Redis/literal/semantic/provider KV caching (implemented on the LiteLLM side). See Wiki for setup
* **Provider‑Agnostic** – Works with OpenAI, Vercel AI Gateway, xAI, Google Vertex, and more through LiteLLM
* **Serious Observability** – Debug telemetry, session analytics, JSON logs, `/status` command
* **Cost Controls** – Canonicalization + hashing, prompt segmentation, provider discounts, usage tracking
* **Drop‑in Friendly** – Fully compatible with upstream `codex` UX, ships as `codex‑litellm` binary

---

## Quick Start

### Prerequisites

* At least one LLM provider API key
* A LiteLLM endpoint (self‑hosted or managed)
* CLI access

> **Note**: The project is written in Rust but distributed as an npm package. A full Node.js dev setup is **not** required for install/use.

### 1) LiteLLM Backend Setup (LiteLLM only)

This fork focuses on native **LiteLLM** integration. Configure LiteLLM first; robust example configs are maintained in the **Wiki**.

**Self‑hosted example**

```bash
docker run -d -p 4000:4000 \
  --name litellm-server \
  litellm/litellm:latest \
  --port 4000
```

### 2) Install `codex‑litellm`

```bash
npm install -g @avikalpa/codex-litellm

# verify
codex-litellm --version
```

#### OpenWrt

Download the `.ipk` for your architecture from the Releases page:

```bash
opkg install codex-litellm_<version>_<arch>.ipk
```

#### Termux (Android)

Use the provided `.deb` artifacts:

```bash
dpkg -i codex-litellm_<version>_aarch64.deb   # or _x86_64
```

Installed at `$PREFIX/bin/codex-litellm`.

#### Optional: Alias

```bash
# shell profile (~/.bashrc, ~/.zshrc)
alias cdxl='codex-litellm'
# To keep config isolated from upstream codex:
alias cdxl='CODEX_HOME=~/.codex-litellm codex-litellm'
source ~/.bashrc  # or ~/.zshrc
```

### 3) Configure

Set the LiteLLM API base and key for `codex‑litellm` to talk to your LiteLLM instance. For **robust, production‑style examples**, see the **Wiki**.

```bash
export LITELLM_BASE_URL="http://localhost:4000"
export LITELLM_API_KEY="your-litellm-api-key"

mkdir -p ~/.codex-litellm
cat > ~/.codex-litellm/config.toml << 'EOF'
[general]
model_provider = "litellm"
api_base = "http://localhost:4000"

[litellm]
api_key = "your-litellm-api-key"
EOF
```

### 4) Smoke Test

```bash
codex-litellm exec "What is the capital of France?"
codex-litellm exec "List files in current directory"
# Interactive mode
codex-litellm
```

More guides: **Wiki** (Quick Start, full configs, and routing recipes).

---

## Architecture

* **Patch Philosophy** – Reproducible diff against upstream `openai/codex` (inspired by GrapheneOS approach)
* **Dual Binary Strategy** – Ships a separate `codex‑litellm` binary; does not disturb the stock `codex` workflow
* **LiteLLM‑Native** – Direct REST integration; graceful fallback for non‑streaming providers

### Caching Strategy

1. **Tier‑0 (Exact‑Match)** – Canonicalization + SHA‑256 on prompts
2. **Tier‑1 (Literal)** – Redis byte‑identical request caching via LiteLLM
3. **Tier‑2 (Semantic)** – Embedding‑based similarity caching with tunable thresholds
4. **Tier‑3 (Provider)** – Provider KV/prompt cache utilization when available

### Observability

* **Debug Telemetry** – Onboarding, model routing, network calls
* **Session Analytics** – Token usage, cache hit‑rates, per‑model stats
* **Structured Logs** – JSON logs with size‑based rotation
* **Live Status** – `/status` command shows health, usage, and routing

---

## Repository Layout

```
├── build.sh                  # Reproducible patch+build pipeline
├── stable-tag.patch          # Patchset against upstream
├── config.toml               # Sample configuration
├── docs/                     # Project docs
│   ├── PROJECT_SUMMARY.md
│   ├── TODOS.md
│   ├── EXCLUSIVE_FEATURES.md
│   └── TELEMETRY.md
├── scripts/                  # npm installer utilities
├── bin/                      # launcher shim
├── litellm/                  # LiteLLM integration modules
├── codex/                    # Upstream checkout (excluded from VCS in releases unless noted)
└── dist/                     # Built artifacts (gitignored)
```

---

## Configuration Notes

### LiteLLM (minimal)

````toml
[general]
api_base = "http://your-litellm-proxy:4000"
model_provider = "litellm"

[litellm]
api_key = "<your-litellm-api-key>"
# Set base_url in LiteLLM itself for chosen providers.
```toml
[general]
api_base = "http://your-litellm-proxy:4000"
model_provider = "litellm"

[litellm]
# Provider endpoints are configured in your LiteLLM server; this CLI just talks to LiteLLM.
````

### Telemetry

```toml
[telemetry]
dir = "logs"
max_total_bytes = 104857600  # 100MB

[telemetry.logs.debug]
enabled = true

[telemetry.logs.session]
file = "codex-litellm-session.jsonl"
```

### Context Window

```toml
[general]
context_length = 130000
```

---

## Local Development

**Requirements**: Rust 1.70+, Node 18+, Redis (for caching features)

```bash
# clone & build
./build.sh

# Android/Termux cross‑compile
USE_CROSS=1 TARGET=aarch64-linux-android ./build.sh

# Dev loop (no full build)
export CODEX_HOME=$(pwd)/test-workspace/.codex
./setup-test-env.sh

cd codex
git checkout rust-v0.53.0
git apply ../stable-tag.patch
cargo build --bin codex
./codex-rs/target/debug/codex exec "test prompt"
```

---

## CI/CD

GitHub Actions builds artifacts for:

* Linux (x64, arm64)
* macOS (x64, arm64)
* Windows (x64, arm64)
* FreeBSD (x64)
* Illumos (x64)
* Android (arm64)

Releases attach binaries and publish to npm when GitHub Release is created.

---

## Performance & Cost

### Best Practices

1. **Tier‑0 exact‑match** canonicalization + hashing
2. **Prompt segmentation** – keep boilerplate separable
3. **Semantic thresholds** – code: ~0.90; NL: 0.86–0.88
4. **Provider selection** – prefer providers with KV/prompt cache discounts

### Monitoring

```bash
codex-litellm /status
export RUST_LOG=debug
codex-litellm exec "your prompt" 2> debug.log
```

Tracks: tokens/session, cache hit‑rates per tier, latency/rate limits, cost per provider.

---

## Troubleshooting

* **"No assistant message"** – Check LiteLLM connectivity, API permissions, inspect debug logs
* **Low cache hit‑rate** – Enable canonicalization; tune thresholds; segment prompts
* **Context pressure** – Reduce `context_length`; use `/compact` to prune

```bash
# Deep debug mode
export RUST_LOG=debug
export CODEX_HOME=./debug-workspace
codex-litellm exec "debug test" 2> debug.log
```

---

## Documentation

**Project Docs**

* `docs/EXCLUSIVE_FEATURES.md` – LiteLLM‑only extras
* `docs/PROJECT_SUMMARY.md` – Current state & internals
* `docs/TODOS.md` – Roadmap
* `AGENTS.md` – Agent workflows
* `TASK.md` – Daily dev notes

**Wiki**

* *An Example of LiteLLM Configuration* – production setup
* *Model Routing Recipes* – cost/latency trade‑offs
* *Embedding Geometry Shootout* – semantic cache tuning
* *Agentic CLI Cost Playbook* – budgeting patterns

---

## Contributing

1. Fork and create a feature branch
2. Check `docs/TODOS.md`
3. Add/update telemetry where relevant
4. Keep patches focused; regenerate `stable-tag.patch`
5. Open a PR with clear tests and notes

---

## Licensing

* **Repository contents:** Apache License 2.0. See [`LICENSE`](LICENSE).
* **Upstream base:** `openai/codex` (Apache‑2.0).

**Releases** built from upstream sources bundle both `LICENSE` and `NOTICE` so downstream redistributors have the required notices.

> Unofficial fork, no affiliation or endorsement implied.

---

> **Disclaimer**: This project is provided “as‑is” with no warranty. Nothing here is legal advice. For edge‑case licensing questions, consult an attorney.
