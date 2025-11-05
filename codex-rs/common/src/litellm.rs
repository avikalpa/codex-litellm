// Copyright (c) 2025 Avikalpa Kundu <avi@gour.top>
// Licensed under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0
// See the NOTICE file distributed with this work for attribution details.

use codex_build_info::{decorate_version as decorate_version_inner, version_with_commit};
use codex_core::config::{
    LiteLlmProviderUpdate, ensure_litellm_baseline, read_litellm_provider_state,
    write_litellm_provider_state,
};
use std::env;
use std::io;
use std::io::IsTerminal;
use std::io::Write as _;
use std::path::Path;

pub const LITELLM_BASE_URL_ENV: &str = "LITELLM_BASE_URL";
pub const LITELLM_API_KEY_ENV: &str = "LITELLM_API_KEY";

pub fn decorate_version(base_version: &str) -> String {
    decorate_version_inner(base_version)
}

pub fn version_with_commit_string() -> String {
    version_with_commit()
}

pub fn ensure_litellm_credentials(codex_home: &Path) -> io::Result<()> {
    ensure_litellm_baseline(codex_home)?;
    let state = read_litellm_provider_state(codex_home)?;
    let mut update = LiteLlmProviderUpdate::default();

    if state.base_url.is_none() {
        let base_url = prompt_or_env("LiteLLM endpoint URL", LITELLM_BASE_URL_ENV, false)?;
        update.base_url = Some(base_url);
    }

    if state.api_key.is_none() {
        let api_key = prompt_or_env("LiteLLM API key", LITELLM_API_KEY_ENV, true)?;
        update.api_key = Some(api_key);
    }

    write_litellm_provider_state(codex_home, update)
}

fn prompt_or_env(label: &str, env_var: &str, secret: bool) -> io::Result<String> {
    if let Ok(value) = env::var(env_var) {
        let trimmed = value.trim();
        if !trimmed.is_empty() {
            eprintln!("{label} sourced from ${env_var}.");
            return Ok(trimmed.to_string());
        }
    }

    if !io::stdin().is_terminal() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            format!("{label} is not configured and ${env_var} is unset."),
        ));
    }

    prompt_for_value(label, secret)
}

fn prompt_for_value(label: &str, secret: bool) -> io::Result<String> {
    loop {
        if secret {
            eprint!("{label}: ");
        } else {
            eprint!("{label}: ");
        }
        io::stderr().flush()?;
        let mut buffer = String::new();
        io::stdin().read_line(&mut buffer)?;
        let value = buffer.trim().to_string();
        if value.is_empty() {
            eprintln!("{label} cannot be empty.");
            continue;
        }
        return Ok(value);
    }
}
