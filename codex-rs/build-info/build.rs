// Copyright (c) 2025 Avikalpa Kundu <avi@gour.top>
// Licensed under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0
// See the NOTICE file distributed with this work for attribution details.

use std::process::Command;

fn resolve_commit() -> String {
    Command::new("git")
        .args(["rev-parse", "--short", "HEAD"])
        .output()
        .ok()
        .and_then(|output| {
            if output.status.success() {
                let trimmed = String::from_utf8_lossy(&output.stdout).trim().to_string();
                if trimmed.is_empty() {
                    None
                } else {
                    Some(trimmed)
                }
            } else {
                None
            }
        })
        .unwrap_or_else(|| "unknown".to_string())
}

fn env_or_resolve(name: &str) -> String {
    std::env::var(name)
        .ok()
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty())
        .unwrap_or_else(resolve_commit)
}

fn main() {
    let upstream = env_or_resolve("CODEX_UPSTREAM_COMMIT");
    let lit = env_or_resolve("CODEX_LITELLM_COMMIT");
    println!("cargo:rustc-env=CODEX_UPSTREAM_COMMIT={upstream}");
    println!("cargo:rustc-env=CODEX_LITELLM_COMMIT={lit}");
}
