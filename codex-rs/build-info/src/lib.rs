// Copyright (c) 2025 Avikalpa Kundu <avi@gour.top>
// Licensed under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0
// See the NOTICE file distributed with this work for attribution details.

pub const CODEX_UPSTREAM_COMMIT: &str = env!("CODEX_UPSTREAM_COMMIT");
pub const CODEX_LITELLM_COMMIT: &str = env!("CODEX_LITELLM_COMMIT");
pub const VERSION_WITH_COMMIT: &str = concat!(
    env!("CARGO_PKG_VERSION"),
    "+",
    env!("CODEX_UPSTREAM_COMMIT"),
    "+lit",
    env!("CODEX_LITELLM_COMMIT")
);

pub fn decorate_version(base_version: &str) -> String {
    format!(
        "{base_version}+{}+lit{}",
        CODEX_UPSTREAM_COMMIT, CODEX_LITELLM_COMMIT
    )
}

pub fn version_with_commit() -> String {
    VERSION_WITH_COMMIT.to_string()
}
