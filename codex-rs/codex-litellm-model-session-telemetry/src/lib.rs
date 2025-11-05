// Copyright (c) 2025 Avikalpa Kundu <avi@gour.top>
// Licensed under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0
// See the NOTICE file distributed with this work for attribution details.

use chrono::{DateTime, SecondsFormat, Utc};
use once_cell::sync::Lazy;
use parking_lot::Mutex;
use serde::Serialize;
use serde_json::json;
use std::collections::BTreeMap;
use std::collections::HashMap;
use std::fs::{File, OpenOptions};
use std::io::{BufWriter, Write};
use std::path::PathBuf;

const DEFAULT_SESSION_KEY: &str = "_default";

#[derive(Debug, Clone, Default, Serialize)]
pub struct ModelUsageSnapshot {
    pub model: String,
    pub turns: u32,
    pub total_tokens: i64,
    pub prompt_tokens: i64,
    pub completion_tokens: i64,
    pub reasoning_tokens: i64,
    pub last_reasoning_effort: Option<String>,
    pub last_updated: DateTime<Utc>,
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct SessionTelemetrySnapshot {
    pub total_turns: u32,
    pub total_tokens: i64,
    pub total_prompt_tokens: i64,
    pub total_completion_tokens: i64,
    pub total_reasoning_tokens: i64,
    pub last_model: Option<String>,
    pub last_reasoning_effort: Option<String>,
    pub last_updated: Option<DateTime<Utc>>,
    pub models: Vec<ModelUsageSnapshot>,
}

#[derive(Debug, Default)]
struct ModelUsageEntry {
    turns: u32,
    total_tokens: i64,
    prompt_tokens: i64,
    completion_tokens: i64,
    reasoning_tokens: i64,
    last_reasoning_effort: Option<String>,
    last_updated: DateTime<Utc>,
}

#[derive(Debug, Default)]
struct SessionTelemetryEntry {
    total_turns: u32,
    total_tokens: i64,
    total_prompt_tokens: i64,
    total_completion_tokens: i64,
    total_reasoning_tokens: i64,
    last_model: Option<String>,
    last_reasoning_effort: Option<String>,
    last_updated: Option<DateTime<Utc>>,
    models: BTreeMap<String, ModelUsageEntry>,
}

static TELEMETRY: Lazy<Mutex<HashMap<String, SessionTelemetryEntry>>> =
    Lazy::new(|| Mutex::new(HashMap::new()));

static LOG_FILE: Lazy<Mutex<Option<LogFile>>> = Lazy::new(|| Mutex::new(None));

struct LogFile {
    writer: BufWriter<File>,
}

impl LogFile {
    fn write_turn(
        &mut self,
        session_id: Option<&str>,
        model: &str,
        reasoning_effort: Option<&str>,
        prompt_tokens: i64,
        completion_tokens: i64,
        reasoning_tokens: i64,
        total_tokens: i64,
    ) -> std::io::Result<()> {
        let record = json!({
            "ts": Utc::now().to_rfc3339_opts(SecondsFormat::Millis, true),
            "session_id": session_id,
            "model": model,
            "reasoning_effort": reasoning_effort,
            "prompt_tokens": prompt_tokens,
            "completion_tokens": completion_tokens,
            "reasoning_tokens": reasoning_tokens,
            "total_tokens": total_tokens,
        });
        serde_json::to_writer(&mut self.writer, &record)?;
        self.writer.write_all(b"\n")?;
        self.writer.flush()?;
        Ok(())
    }
}

fn normalize_session_id(session_id: Option<&str>) -> String {
    session_id
        .map(|id| id.trim().to_string())
        .filter(|id| !id.is_empty())
        .unwrap_or_else(|| DEFAULT_SESSION_KEY.to_string())
}

pub fn configure_log_file(path: Option<PathBuf>) -> std::io::Result<()> {
    let mut guard = LOG_FILE.lock();
    if let Some(path) = path {
        let mut opts = OpenOptions::new();
        opts.create(true).append(true).write(true);
        #[cfg(unix)]
        {
            use std::os::unix::fs::OpenOptionsExt;
            opts.mode(0o600);
        }
        let file = opts.open(path)?;
        *guard = Some(LogFile {
            writer: BufWriter::new(file),
        });
    } else {
        guard.take();
    }
    Ok(())
}

pub fn clear_session(session_id: Option<&str>) {
    let key = normalize_session_id(session_id);
    TELEMETRY.lock().remove(&key);
}

pub fn record_turn(
    session_id: Option<&str>,
    model: &str,
    reasoning_effort: Option<&str>,
    prompt_tokens: i64,
    completion_tokens: i64,
    reasoning_tokens: i64,
    total_tokens: i64,
) {
    let key = normalize_session_id(session_id);
    let mut guard = TELEMETRY.lock();
    let entry = guard.entry(key).or_default();

    let now = Utc::now();
    let model_entry = entry
        .models
        .entry(model.to_string())
        .or_insert_with(ModelUsageEntry::default);

    model_entry.turns = model_entry.turns.saturating_add(1);
    model_entry.total_tokens += total_tokens;
    model_entry.prompt_tokens += prompt_tokens;
    model_entry.completion_tokens += completion_tokens;
    model_entry.reasoning_tokens += reasoning_tokens;
    model_entry.last_reasoning_effort = reasoning_effort.map(|effort| effort.to_string());
    model_entry.last_updated = now;

    entry.total_turns = entry.total_turns.saturating_add(1);
    entry.total_tokens += total_tokens;
    entry.total_prompt_tokens += prompt_tokens;
    entry.total_completion_tokens += completion_tokens;
    entry.total_reasoning_tokens += reasoning_tokens;
    entry.last_model = Some(model.to_string());
    entry.last_reasoning_effort = reasoning_effort.map(|effort| effort.to_string());
    entry.last_updated = Some(now);

    drop(guard);

    {
        let mut log_guard = LOG_FILE.lock();
        if let Some(log_file) = log_guard.as_mut() {
            if let Err(err) = log_file.write_turn(
                session_id,
                model,
                reasoning_effort,
                prompt_tokens,
                completion_tokens,
                reasoning_tokens,
                total_tokens,
            ) {
                eprintln!(
                    "[codex-litellm-model-session-telemetry] failed to write log entry: {err}"
                );
            }
        }
    }
}

pub fn snapshot(session_id: Option<&str>) -> Option<SessionTelemetrySnapshot> {
    let key = normalize_session_id(session_id);
    let guard = TELEMETRY.lock();
    let entry = guard.get(&key)?;

    let mut models: Vec<ModelUsageSnapshot> = entry
        .models
        .iter()
        .map(|(model, usage)| ModelUsageSnapshot {
            model: model.clone(),
            turns: usage.turns,
            total_tokens: usage.total_tokens,
            prompt_tokens: usage.prompt_tokens,
            completion_tokens: usage.completion_tokens,
            reasoning_tokens: usage.reasoning_tokens,
            last_reasoning_effort: usage.last_reasoning_effort.clone(),
            last_updated: usage.last_updated,
        })
        .collect();

    models.sort_by(|a, b| b.total_tokens.cmp(&a.total_tokens));

    Some(SessionTelemetrySnapshot {
        total_turns: entry.total_turns,
        total_tokens: entry.total_tokens,
        total_prompt_tokens: entry.total_prompt_tokens,
        total_completion_tokens: entry.total_completion_tokens,
        total_reasoning_tokens: entry.total_reasoning_tokens,
        last_model: entry.last_model.clone(),
        last_reasoning_effort: entry.last_reasoning_effort.clone(),
        last_updated: entry.last_updated,
        models,
    })
}
