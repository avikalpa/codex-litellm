# --web flag
- We can run codex-litellm in lxc containers or VMs, giving them access to tools and exposing endpoints like codex/dev0/gpt-oss-120b to open-webui to be the "self-hosted" online version of both codex and agentic chatting (extended thinking or Heavy stuff).
- This ensures that we need not make another webui and use the pre-existing self-hosted solution which is very good.
- We need need to expose the config of the "listening" mode of codex-litellm by adding flags in the config.toml, considering how situations might arise, viz. multiple models, many dev. or "work" env. Also API KEY and SALT system for token authentication.
