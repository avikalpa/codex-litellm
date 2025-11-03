# codex-litellm

A **patched build of the OpenAI Codex CLI** that enables direct communication with LiteLLM backends without requiring an external proxy. This fork maintains full compatibility with the upstream `codex` binary while adding comprehensive LiteLLM integration, advanced caching strategies, and observability features.

## Key Features

- **Direct LiteLLM Integration**: Native communication with LiteLLM APIs, eliminating external proxy dependencies
- **Multi-Layer Caching**: Tier-0 exact-match, Redis literal cache, and semantic cache support
- **Provider Agnostic**: Support for OpenAI, Vercel AI Gateway, xAI, Google Vertex, and more through LiteLLM
- **Advanced Observability**: Built-in telemetry, debug logging, and session analytics
- **Cost Optimization**: Intelligent retry logic, prompt caching, and usage tracking
- **Enterprise Ready**: Production-grade configuration, error handling, and monitoring

## 🚀 Quick Start

### Prerequisites

Before installation, ensure you have:
- Access to at least one LLM provider API key
- A LiteLLM backend endpoint (cloud or self-hosted)
- Command line access

**Note**: While this project is written in Rust, it uses npm for binary distribution. No Node.js development environment is required.

### Step 1: LiteLLM Backend Setup

The LiteLLM backend can be configured in multiple ways:

#### Option A: LiteLLM Cloud Service
Deploy LiteLLM Cloud or use a managed service to obtain your endpoint URL and API key.

#### Option B: Self-Hosted LiteLLM Server

```bash
# Deploy with Docker
docker run -d -p 4000:4000 \
  --name litellm-server \
  litellm/litellm:latest \
  --port 4000
```

#### Option C: Environment Variable Configuration
Set up LiteLLM during the initial codex-litellm onboarding process or configure via environment variables:

```bash
export LITELLM_BASE_URL="your-litellm-endpoint"
export LITELLM_API_KEY="your-api-key"
```

### Step 2: Installation

```bash
# Install via npm (binary distribution)
npm install -g @avikalpa/codex-litellm

# Verify installation
codex-litellm --version
```

#### Optional: Create Command Alias

For convenient usage, you can create an alias:

```bash
# Add to shell profile (~/.bashrc, ~/.zshrc, etc.)
alias cdxl='codex-litellm'

# Optional: For complete separation from upstream codex config:
alias cdxl='CODEX_HOME=~/.codex-litellm codex-litellm'

# Apply the alias
source ~/.bashrc  # or source ~/.zshrc
```

The `CODEX_HOME` override is optional - use it only if you want complete separation of configuration data between this fork and the upstream OpenAI Codex CLI.

Now use `cdxl` instead of `codex-litellm` in all commands.

### Step 3: Configuration

```bash
# Set environment variables
export LITELLM_API_KEY="your-litellm-api-key"
export LITELLM_BASE_URL="http://localhost:4000"  # Your LiteLLM endpoint

# Create workspace and configuration
mkdir -p ~/.codex-litellm
cat > ~/.codex-litellm/config.toml << 'EOF'
[general]
model_provider = "litellm"
api_base = "http://localhost:4000"

[litellm]
api_key = "your-litellm-api-key"
EOF
```

### Step 4: Verification

```bash
# Test basic functionality (or use alias: cdxl exec "...")
codex-litellm exec "What is the capital of France?"

# Test tool execution
codex-litellm exec "List files in current directory"

# Start interactive mode
codex-litellm
```

After setting up the alias, you can use `cdxl` instead of `codex-litellm` in all commands.

For detailed platform-specific instructions, see the [Quick Start Guide](https://github.com/avikalpa/codex-litellm/wiki/Quick-Start).

## 🏗️ Architecture

### Core Components

- **Patch Philosophy**: Inspired by GrapheneOS, maintains reproducible diffs against upstream `openai/codex`
- **Dual Binary Strategy**: Ships as `codex-litellm` alongside stock `codex` for seamless migration
- **LiteLLM Native**: Direct API integration with fallback to non-streaming responses when needed

### Caching Strategy

The project implements a sophisticated multi-tier caching system:

1. **Tier-0 (Exact-Match)**: Canonicalization + SHA-256 hashing before LiteLLM
2. **Tier-1 (Literal)**: Redis-based byte-identical request caching via LiteLLM
3. **Tier-2 (Semantic)**: High-fidelity embedding-based similarity caching
4. **Tier-3 (Provider)**: Leverages provider-side KV/prompt caching when available

### Observability Stack

- **Debug Telemetry**: High-fidelity event tracing for onboarding, model selection, and network calls
- **Session Analytics**: Token usage, model performance, and cost tracking
- **Structured Logging**: JSON-formatted logs with configurable retention policies
- **Real-time Status**: Built-in `/status` command for usage insights

## 📁 Repository Structure

```
├── build.sh                 # Reproducible patch + build pipeline
├── stable-tag.patch         # Comprehensive patchset against upstream
├── config.toml              # Sample LiteLLM configuration
├── docs/                    # Project documentation
│   ├── PROJECT_SUMMARY.md   # Current status and progress
│   ├── TODOS.md            # Roadmap and task tracking
│   ├── EXCLUSIVE_FEATURES.md # LiteLLM-specific features
│   └── TELEMETRY.md        # Observability guide
├── scripts/                # npm installer utilities
├── bin/                    # Binary launcher shim
├── litellm/                # LiteLLM integration modules
├── codex/                  # Upstream source checkout
└── dist/                   # Generated binaries (gitignored)
```

## 🔧 Configuration

### LiteLLM Setup

```toml
[general]
api_base = "http://your-litellm-proxy:4000"
model_provider = "litellm"

[litellm]
# Vercel AI Gateway (recommended)
api_key = "sk-vercel-..."
base_url = "https://gateway.vercel.ai"

# Alternative: Direct provider setup
# api_key = "sk-openai-..."
# base_url = "https://api.openai.com/v1"
```

### Caching Configuration

```toml
[telemetry]
dir = "logs"
max_total_bytes = 104857600  # 100MB log rotation

[telemetry.logs.debug]
enabled = true

[telemetry.logs.session]
file = "codex-litellm-session.jsonl"
```

### Context Window Management

```toml
[general]
# 130k token context window (configurable)
context_length = 130000
```

## 🏗️ Local Development

### Prerequisites

- Rust 1.70+
- Node 18+
- Redis (for caching features)

### Build Process

```bash
# Clone the repository
git clone https://github.com/avikalpa/codex-litellm
cd codex-litellm

# Native build
./build.sh

# Cross-compilation for Android/termux
USE_CROSS=1 TARGET=aarch64-linux-android ./build.sh
```

### Development Workflow

```bash
# Set up isolated test environment
export CODEX_HOME=$(pwd)/test-workspace/.codex
./setup-test-env.sh

# Manual development builds (avoid build.sh during dev)
cd codex
git checkout rust-v0.53.0
git apply ../stable-tag.patch
cargo build --bin codex

# Test with debug binary
./codex-rs/target/debug/codex exec "test prompt"
```

## 🔄 CI/CD Pipeline

The GitHub Actions workflow builds on every push/PR, generating binaries for:

- Linux (x64, arm64)
- macOS (x64, arm64)
- Windows (x64, arm64)
- FreeBSD (x64)
- Illumos (x64)
- Android (arm64)

Release automation attaches artifacts and publishes to npm when a GitHub release is created.

## 📊 Performance & Cost Optimization

### Caching Best Practices

1. **Tier-0 Exact-Match**: Implement canonicalization and hashing for maximum reuse
2. **Prompt Segmentation**: Separate static boilerplate from dynamic content
3. **Semantic Tuning**: Use `similarity_threshold: 0.90` for code, `0.86-0.88` for NL
4. **Provider Selection**: Choose providers with prompt caching discounts

### Cost Controls

```bash
# Monitor usage in real-time
codex-litellm /status

# Enable debug telemetry for optimization
export RUST_LOG=debug
codex-litellm exec "your prompt" 2> debug.log
```

### Performance Metrics

The built-in telemetry tracks:
- Token usage per model and session
- Cache hit rates across all tiers
- Request latency and retry statistics
- Cost breakdowns by provider

## 🛠️ Troubleshooting

### Common Issues

**"No assistant message" errors**
- Check LiteLLM backend connectivity
- Verify API key permissions
- Review debug telemetry logs

**Low cache hit rates**
- Enable prompt canonicalization
- Adjust similarity thresholds
- Segment prompts effectively

**Memory/context issues**
- Reduce `context_length` in config
- Use `/compact` to clean up history
- Monitor session token usage

### Debug Mode

```bash
# Enable comprehensive logging
export RUST_LOG=debug
export CODEX_HOME=./debug-workspace
codex-litellm exec "debug test" 2> debug.log
```

## 📚 Documentation & Resources

### Project Documentation

- **[Exclusive Features](docs/EXCLUSIVE_FEATURES.md)**: LiteLLM-specific features and capabilities
- **[Project Summary](docs/PROJECT_SUMMARY.md)**: Current status and technical details
- **[Todo List](docs/TODOS.md)**: Development roadmap and priorities
- **[Agent Guide](AGENTS.md)**: Development workflow and collaboration
- **[Task Log](TASK.md)**: Daily development notes and progress

### Wiki Resources

The [GitHub Wiki](https://github.com/avikalpa/codex-litellm/wiki) contains practical guides:

- **[LiteLLM Configuration](wiki/An-Example-of-LiteLLM-Configuration)**: Production-ready setup
- **[Model Routing Recipes](wiki/Model-Routing-Recipes)**: Cost and latency optimization
- **[Cache Performance Guide](wiki/Embedding-Geometry-Shootout)**: Semantic cache tuning
- **[Cost Playbook](wiki/Agentic-CLI-Cost-Playbook)**: Budget optimization strategies

### External References

- [LiteLLM Documentation](https://docs.litellm.ai/)
- [OpenAI Codex CLI](https://github.com/openai/codex)
- [Redis Caching](https://redis.io/docs/data-types/caching/)
- [Vercel AI Gateway](https://vercel.com/docs/ai-gateway)

## 🤝 Contributing

We welcome contributions! Please see our contribution guidelines:

1. **Fork** the repository and create a feature branch
2. **Review** `docs/TODOS.md` for current priorities
3. **Test** changes with the provided test workspace
4. **Document** new features with appropriate telemetry
5. **Submit** a PR with clear description and testing notes

### Development Guidelines

- Use `setup-test-env.sh` for isolated testing
- Keep patches focused and well-documented
- Regenerate `stable-tag.patch` after any code changes
- Add telemetry events for new features
- Follow Rust and Node.js best practices

## 📄 License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

**License Compatibility Note**: This project is derived from the upstream OpenAI Codex CLI, which is licensed under the Apache License. When deploying or modifying this software, please ensure compliance with both license terms.

## 🙏 Acknowledgments

- **OpenAI** for the original Codex CLI and foundational technology
- **LiteLLM** team for the excellent proxy infrastructure and API standardization
- **Vercel** for AI Gateway services and high-quality embedding models
- **Contributors** and community members who have provided feedback, testing, and improvements

---

**Note**: This project is independently maintained. For issues specific to the upstream Codex CLI, please refer to the [official OpenAI repository](https://github.com/openai/codex).