// Copyright (c) 2025 Avikalpa Kundu <avi@gour.top>
// Licensed under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0
// See the NOTICE file distributed with this work for attribution details.

use codex_common::model_presets::{
    ModelPreset, builtin_model_presets, fetch_litellm_model_presets, is_litellm_provider_id,
    presets_for_provider,
};
use codex_core::config::Config;
use codex_core::config::edit::{ConfigEdit, apply_blocking};
use codex_core::config::read_litellm_provider_state;
use codex_core::protocol_config_types::ReasoningEffort;
use crossterm::event::{KeyCode, KeyEvent, KeyEventKind};
use ratatui::buffer::Buffer;
use ratatui::layout::{Constraint, Layout, Rect};
use ratatui::style::{Color, Modifier, Style, Stylize};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Clear, Paragraph, Widget, WidgetRef, Wrap};
use std::cell::Cell;

use super::onboarding_screen::{KeyboardHandler, StepState, StepStateProvider};
use crate::style::user_message_style;
use crate::tui::FrameRequester;

#[derive(Clone)]
pub(crate) struct ModelSelectionResult {
    pub model: String,
    pub reasoning_effort: Option<ReasoningEffort>,
}

#[derive(Clone)]
struct ReasoningOption {
    effort: Option<ReasoningEffort>,
    label: String,
    description: Option<String>,
    selected_description: Option<String>,
}

struct ReasoningStageState {
    preset_index: usize,
    options: Vec<ReasoningOption>,
    selected_index: usize,
    scroll_offset: Cell<usize>,
    visible_capacity: Cell<usize>,
}

impl ReasoningStageState {
    fn new(preset_index: usize, options: Vec<ReasoningOption>, selected_index: usize) -> Self {
        Self {
            preset_index,
            options,
            selected_index,
            scroll_offset: Cell::new(0),
            visible_capacity: Cell::new(0),
        }
    }
}

enum SelectionStage {
    ModelList,
    Reasoning(ReasoningStageState),
}

enum ModelStepStatus {
    Hidden,
    AwaitingCredentials,
    Loading,
    Ready,
    Saving,
    Complete,
    Error(String),
}

pub(crate) struct ModelSelectionWidget {
    request_frame: FrameRequester,
    config: Config,
    presets: Vec<ModelPreset>,
    selected_index: usize,
    status: ModelStepStatus,
    selection_result: Option<ModelSelectionResult>,
    stage: SelectionStage,
    scroll_offset: Cell<usize>,
    visible_capacity: Cell<usize>,
}

impl ModelSelectionWidget {
    pub(crate) fn new(request_frame: FrameRequester, config: Config) -> Self {
        let mut widget = Self {
            request_frame,
            config,
            presets: Vec::new(),
            selected_index: 0,
            status: ModelStepStatus::Hidden,
            selection_result: None,
            stage: SelectionStage::ModelList,
            scroll_offset: Cell::new(0),
            visible_capacity: Cell::new(1),
        };

        if is_litellm_provider_id(&widget.config.model_provider_id) {
            if widget.config.litellm_setup_required {
                widget.status = ModelStepStatus::AwaitingCredentials;
            } else {
                widget.load_presets();
            }
        }

        widget
    }

    pub(crate) fn credentials_ready(&mut self) {
        if matches!(self.status, ModelStepStatus::AwaitingCredentials) {
            self.load_presets();
        }
    }

    pub(crate) fn selection(&self) -> Option<ModelSelectionResult> {
        self.selection_result.clone()
    }

    fn load_presets(&mut self) {
        self.status = ModelStepStatus::Loading;
        #[cfg(debug_assertions)]
        tracing::debug!(
            provider = %self.config.model_provider_id,
            "model_onboarding.load_presets:start"
        );
        tracing::info!(
            target: "codex_litellm_debug::onboarding",
            provider = %self.config.model_provider_id,
            "model_onboarding.load_presets:start"
        );
        self.request_frame.schedule_frame();

        match self.fetch_presets() {
            Ok(presets) if !presets.is_empty() => {
                self.apply_loaded_presets(presets);
                #[cfg(debug_assertions)]
                tracing::debug!(
                    provider = %self.config.model_provider_id,
                    count = self.presets.len(),
                    "model_onboarding.load_presets:ready"
                );
                tracing::info!(
                    target: "codex_litellm_debug::onboarding",
                    provider = %self.config.model_provider_id,
                    count = self.presets.len(),
                    "model_onboarding.load_presets:ready"
                );
            }
            Ok(_) => {
                self.status = ModelStepStatus::Error(
                    "LiteLLM returned no models. Use /model later to configure.".to_string(),
                );
                #[cfg(debug_assertions)]
                tracing::debug!("model_onboarding.load_presets:empty");
                tracing::warn!(
                    target: "codex_litellm_debug::onboarding",
                    provider = %self.config.model_provider_id,
                    "model_onboarding.load_presets:empty"
                );
            }
            Err(err) => {
                #[cfg(debug_assertions)]
                tracing::debug!(error = %err, "model_onboarding.load_presets:error");
                tracing::warn!(
                    target: "codex_litellm_debug::onboarding",
                    provider = %self.config.model_provider_id,
                    error = %err,
                    "model_onboarding.load_presets:error"
                );
                self.status = ModelStepStatus::Error(err);
            }
        }
        self.request_frame.schedule_frame();
    }

    fn apply_loaded_presets(&mut self, presets: Vec<ModelPreset>) {
        self.presets = presets;
        tracing::info!(
            target: "codex_litellm_debug::onboarding",
            provider = %self.config.model_provider_id,
            current = %self.config.model,
            count = self.presets.len(),
            "model_onboarding.apply_loaded_presets"
        );
        self.selected_index = 0;
        self.scroll_offset.set(0);
        self.visible_capacity.set(1);
        self.stage = SelectionStage::ModelList;
        self.status = ModelStepStatus::Ready;
        self.config.litellm_setup_required = false;
    }

    fn fetch_presets(&self) -> Result<Vec<ModelPreset>, String> {
        if is_litellm_provider_id(&self.config.model_provider_id) {
            let state = read_litellm_provider_state(&self.config.codex_home)
                .map_err(|err| format!("Failed to read LiteLLM credentials: {err}"))?;
            let base_url = state.base_url.ok_or_else(|| {
                "LiteLLM endpoint URL is missing. Re-enter it during onboarding.".to_string()
            })?;
            return fetch_litellm_model_presets(
                &base_url,
                state.api_key.as_deref(),
                &self.config.model,
            );
        }

        let mut presets =
            presets_for_provider(&self.config.model_provider_id, &self.config.model, None);
        if presets.is_empty() {
            presets = builtin_model_presets(None);
        }
        if presets.is_empty() {
            return Err("No models available for the current provider.".to_string());
        }
        for preset in presets.iter_mut() {
            preset.is_default = preset.model == self.config.model;
        }
        Ok(presets)
    }

    fn begin_reasoning_stage(&mut self) {
        if self.presets.is_empty() {
            return;
        }
        let preset_index = self.selected_index.min(self.presets.len() - 1);
        let preset = self.presets[preset_index].clone();
        let options = self.build_reasoning_options(&preset);

        let target_effort = if preset.model == self.config.model {
            self.config.model_reasoning_effort
        } else {
            Some(preset.default_reasoning_effort)
        };
        let default_effort = Some(preset.default_reasoning_effort);
        let selected_index = options
            .iter()
            .position(|opt| opt.effort == target_effort)
            .or_else(|| options.iter().position(|opt| opt.effort == default_effort))
            .unwrap_or(0);

        self.stage = SelectionStage::Reasoning(ReasoningStageState::new(
            preset_index,
            options,
            selected_index,
        ));
        self.request_frame.schedule_frame();
    }

    fn build_reasoning_options(&self, preset: &ModelPreset) -> Vec<ReasoningOption> {
        let supported = preset.supported_reasoning_efforts;
        let default_effort = preset.default_reasoning_effort;

        let mut options: Vec<ReasoningOption> = supported
            .iter()
            .map(|entry| {
                let mut label = entry.effort.to_string();
                if let Some(first) = label.get_mut(0..1) {
                    first.make_ascii_uppercase();
                }
                if entry.effort == default_effort {
                    label.push_str(" (default)");
                }

                let description =
                    (!entry.description.is_empty()).then(|| entry.description.to_string());
                let warning =
                    if preset.model == "gpt-5-codex" && entry.effort == ReasoningEffort::High {
                        Some(
                            "⚠ High reasoning effort can quickly consume Plus plan rate limits."
                                .to_string(),
                        )
                    } else {
                        None
                    };

                ReasoningOption {
                    effort: Some(entry.effort),
                    label,
                    description,
                    selected_description: warning,
                }
            })
            .collect();

        if options.is_empty() {
            let mut label = default_effort.to_string();
            if let Some(first) = label.get_mut(0..1) {
                first.make_ascii_uppercase();
            }

            options.push(ReasoningOption {
                effort: Some(default_effort),
                label,
                description: None,
                selected_description: None,
            });
        }

        options
    }

    fn confirm_reasoning_selection(&mut self) {
        let selection = match &self.stage {
            SelectionStage::Reasoning(state) => state
                .options
                .get(state.selected_index)
                .cloned()
                .map(|option| (state.preset_index, option)),
            _ => None,
        };

        if let Some((preset_index, option)) = selection {
            self.save_selection(preset_index, option.effort);
        }
    }

    fn save_selection(&mut self, preset_index: usize, selected_effort: Option<ReasoningEffort>) {
        let Some(selected_preset) = self.presets.get(preset_index).cloned() else {
            return;
        };

        self.status = ModelStepStatus::Saving;
        self.request_frame.schedule_frame();

        let codex_home = self.config.codex_home.clone();
        let active_profile = self.config.active_profile.clone();
        let model = selected_preset.model.clone();

        let apply_result = apply_blocking(
            &codex_home,
            active_profile.as_deref(),
            &[ConfigEdit::SetModel {
                model: Some(model.clone()),
                effort: selected_effort,
            }],
        );

        match apply_result {
            Ok(()) => {
                for (idx, preset) in self.presets.iter_mut().enumerate() {
                    preset.is_default = idx == preset_index;
                }
                tracing::info!(
                    target: "codex_litellm_debug::onboarding",
                    provider = %self.config.model_provider_id,
                    model = %selected_preset.model,
                    reasoning = ?selected_effort,
                    "model_onboarding.save_selection:complete"
                );
                self.selected_index = preset_index;
                self.scroll_offset.set(0);
                self.visible_capacity.set(1);
                self.selection_result = Some(ModelSelectionResult {
                    model: model.clone(),
                    reasoning_effort: selected_effort,
                });
                self.config.model = model;
                self.config.model_reasoning_effort = selected_effort;
                self.stage = SelectionStage::ModelList;
                self.status = ModelStepStatus::Complete;
            }
            Err(err) => {
                self.status =
                    ModelStepStatus::Error(format!("Failed to write model selection: {err}"));
                tracing::warn!(
                    target: "codex_litellm_debug::onboarding",
                    provider = %self.config.model_provider_id,
                    model = %selected_preset.model,
                    error = %err,
                    "model_onboarding.save_selection:error"
                );
            }
        }

        self.request_frame.schedule_frame();
    }

    fn move_model_selection(&mut self, delta: isize) {
        if !matches!(
            self.status,
            ModelStepStatus::Ready | ModelStepStatus::Error(_)
        ) {
            return;
        }
        if !matches!(self.stage, SelectionStage::ModelList) {
            return;
        }
        let len = self.presets.len();
        if len == 0 {
            return;
        }
        let next = (self.selected_index as isize + delta).rem_euclid(len as isize);
        self.selected_index = next as usize;
        self.adjust_model_scroll();
        self.request_frame.schedule_frame();
    }

    fn move_model_selection_page(&mut self, delta_pages: isize) {
        if !matches!(self.stage, SelectionStage::ModelList) {
            return;
        }
        let len = self.presets.len();
        if len == 0 {
            return;
        }
        let page = self.visible_capacity.get().max(1) as isize;
        let mut target = self.selected_index as isize + delta_pages * page;
        target = target.clamp(0, len as isize - 1);
        self.selected_index = target as usize;
        self.adjust_model_scroll();
        self.request_frame.schedule_frame();
    }

    fn move_reasoning_selection(&mut self, delta: isize) {
        let SelectionStage::Reasoning(state) = &mut self.stage else {
            return;
        };
        let len = state.options.len();
        if len == 0 {
            return;
        }
        let next = (state.selected_index as isize + delta).rem_euclid(len as isize);
        state.selected_index = next as usize;
        Self::adjust_reasoning_scroll(state);
        self.request_frame.schedule_frame();
    }

    fn move_reasoning_selection_page(&mut self, delta_pages: isize) {
        let SelectionStage::Reasoning(state) = &mut self.stage else {
            return;
        };
        let len = state.options.len();
        if len == 0 {
            return;
        }
        let page = state.visible_capacity.get().max(1) as isize;
        let mut target = state.selected_index as isize + delta_pages * page;
        target = target.clamp(0, len as isize - 1);
        state.selected_index = target as usize;
        Self::adjust_reasoning_scroll(state);
        self.request_frame.schedule_frame();
    }

    fn adjust_model_scroll(&self) {
        let visible = self.visible_capacity.get().max(1);
        let len = self.presets.len();
        if len <= visible {
            self.scroll_offset.set(0);
            return;
        }
        let max_offset = len - visible;
        let mut offset = self.scroll_offset.get().min(max_offset);
        if self.selected_index < offset {
            offset = self.selected_index;
        } else if self.selected_index >= offset + visible {
            offset = self.selected_index + 1 - visible;
        }
        self.scroll_offset.set(offset);
    }

    fn adjust_reasoning_scroll(state: &ReasoningStageState) {
        let visible = state.visible_capacity.get().max(1);
        let len = state.options.len();
        if len <= visible {
            state.scroll_offset.set(0);
            return;
        }
        let max_offset = len - visible;
        let mut offset = state.scroll_offset.get().min(max_offset);
        if state.selected_index < offset {
            offset = state.selected_index;
        } else if state.selected_index >= offset + visible {
            offset = state.selected_index + 1 - visible;
        }
        state.scroll_offset.set(offset);
    }

    fn render_loading(&self, area: Rect, buf: &mut Buffer) {
        let lines = vec![
            Line::from("Connecting to LiteLLM…".bold()),
            Line::from("Fetching available models. This may take a moment.".dim()),
        ];
        Paragraph::new(lines)
            .block(Block::default().borders(Borders::ALL))
            .wrap(Wrap { trim: false })
            .render(area, buf);
    }

    fn render_error(&self, area: Rect, buf: &mut Buffer, message: &str) {
        let lines = vec![
            Line::from("Model selection unavailable".bold().fg(Color::Red)),
            Line::from(message),
            Line::from(""),
            Line::from("Press Enter or Esc to continue without selecting a model."),
        ];
        Paragraph::new(lines)
            .block(Block::default().borders(Borders::ALL))
            .wrap(Wrap { trim: false })
            .render(area, buf);
    }

    fn render_ready(&self, area: Rect, buf: &mut Buffer) {
        match &self.stage {
            SelectionStage::ModelList => self.render_model_stage(area, buf),
            SelectionStage::Reasoning(state) => self.render_reasoning_stage(area, buf, state),
        }
    }

    fn render_model_stage(&self, area: Rect, buf: &mut Buffer) {
        let instructions = vec![
            Line::from("Select a LiteLLM model for Codex CLI.".bold()),
            Line::from("Use ↑/↓ (PageUp/PageDown) to browse models.".dim()),
            Line::from("Press Enter to choose reasoning level. Esc skips selection.".dim()),
        ];
        let instruction_height = instructions.len() as u16 + 1;
        let instruction_height = instruction_height.min(area.height);

        let [instructions_area, list_area] =
            Layout::vertical([Constraint::Length(instruction_height), Constraint::Min(3)])
                .areas(area);

        Block::default()
            .style(user_message_style())
            .render(area, buf);

        Paragraph::new(instructions)
            .wrap(Wrap { trim: false })
            .render(instructions_area, buf);

        if list_area.height == 0 {
            return;
        }

        let max_visible = list_area.height.saturating_sub(2).max(1) as usize;
        self.visible_capacity.set(max_visible.max(1));
        self.adjust_model_scroll();

        let len = self.presets.len();
        if len == 0 {
            Paragraph::new(vec![Line::from(
                "No models available. Configure LiteLLM and try again later.",
            )])
            .wrap(Wrap { trim: false })
            .render(list_area, buf);
            return;
        }

        let offset = self.scroll_offset.get();
        let visible = self.visible_capacity.get().max(1);
        let end = (offset + visible).min(len);
        let mut lines: Vec<Line<'static>> = Vec::new();
        for (row, preset) in self.presets[offset..end].iter().enumerate() {
            let idx = offset + row;
            let is_selected = idx == self.selected_index;
            let prefix = if is_selected { '›' } else { ' ' };
            let display_index = idx + 1;
            let display_name = if preset.display_name.is_empty() {
                preset.model.as_str()
            } else {
                preset.display_name.as_str()
            };

            let mut spans: Vec<Span> = vec![
                Span::styled(prefix.to_string(), Style::default().fg(Color::Gray)),
                Span::raw(" "),
                Span::raw(format!("{display_index}. ")),
                Span::raw(display_name.to_string()),
                Span::raw(" "),
                Span::styled(preset.model.to_string(), Style::default().italic().dim()),
            ];
            if preset.is_default {
                spans.push(Span::raw(" "));
                spans.push(Span::styled("(current)", Style::default().dim()));
            }

            if is_selected {
                for span in spans.iter_mut() {
                    span.style = span
                        .style
                        .fg(Color::Cyan)
                        .add_modifier(Modifier::BOLD | Modifier::REVERSED);
                }
            }
            lines.push(Line::from(spans));

            if let Some(desc) = preset.description.as_ref().filter(|d| !d.is_empty()) {
                let mut desc_spans = vec![
                    Span::raw("    "),
                    Span::styled(desc.to_string(), Style::default().dim()),
                ];
                if is_selected {
                    for span in desc_spans.iter_mut() {
                        span.style = span
                            .style
                            .fg(Color::Cyan)
                            .add_modifier(Modifier::BOLD | Modifier::REVERSED);
                    }
                }
                lines.push(Line::from(desc_spans));
            }
        }

        Paragraph::new(lines)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .style(user_message_style()),
            )
            .wrap(Wrap { trim: false })
            .render(list_area, buf);
    }

    fn render_reasoning_stage(&self, area: Rect, buf: &mut Buffer, state: &ReasoningStageState) {
        let instructions = vec![
            Line::from("Choose how much reasoning the model should use.".bold()),
            Line::from(
                "Use ↑/↓ (PageUp/PageDown) to browse. Enter to confirm. Esc to go back.".dim(),
            ),
        ];
        let instruction_height = instructions.len() as u16 + 1;
        let instruction_height = instruction_height.min(area.height);

        let [instructions_area, list_area] =
            Layout::vertical([Constraint::Length(instruction_height), Constraint::Min(3)])
                .areas(area);

        Block::default()
            .style(user_message_style())
            .render(area, buf);

        Paragraph::new(instructions)
            .wrap(Wrap { trim: false })
            .render(instructions_area, buf);

        if list_area.height == 0 {
            return;
        }

        let max_visible = list_area.height.saturating_sub(2).max(1) as usize;
        state.visible_capacity.set(max_visible.max(1));
        Self::adjust_reasoning_scroll(state);

        let len = state.options.len();
        if len == 0 {
            Paragraph::new(vec![Line::from("No reasoning options available.")])
                .wrap(Wrap { trim: false })
                .render(list_area, buf);
            return;
        }

        let offset = state.scroll_offset.get();
        let visible = state.visible_capacity.get().max(1);
        let end = (offset + visible).min(len);
        let mut lines: Vec<Line<'static>> = Vec::new();
        for (row, option) in state.options[offset..end].iter().enumerate() {
            let idx = offset + row;
            let is_selected = idx == state.selected_index;
            let prefix = if is_selected { '›' } else { ' ' };
            let mut spans: Vec<Span> = vec![
                Span::styled(prefix.to_string(), Style::default().fg(Color::Gray)),
                Span::raw(" "),
                Span::styled(
                    option.label.clone(),
                    if is_selected {
                        Style::default()
                            .fg(Color::Cyan)
                            .add_modifier(Modifier::BOLD | Modifier::REVERSED)
                    } else {
                        Style::default().add_modifier(Modifier::DIM)
                    },
                ),
            ];
            if let Some(desc) = option.description.as_ref() {
                spans.push(Span::raw("  "));
                spans.push(Span::styled(
                    desc.clone(),
                    if is_selected {
                        Style::default()
                            .fg(Color::Cyan)
                            .add_modifier(Modifier::ITALIC | Modifier::DIM)
                    } else {
                        Style::default().add_modifier(Modifier::DIM)
                    },
                ));
            }

            lines.push(Line::from(spans));

            if is_selected {
                if let Some(extra) = option.selected_description.as_ref() {
                    lines.push(Line::from(vec![Span::styled(
                        format!("    {extra}"),
                        Style::default()
                            .fg(Color::Yellow)
                            .add_modifier(Modifier::BOLD),
                    )]));
                }
            }
        }

        Paragraph::new(lines)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .style(user_message_style()),
            )
            .wrap(Wrap { trim: false })
            .render(list_area, buf);
    }

    fn render_completion(&self, area: Rect, buf: &mut Buffer) {
        let result = self.selection_result.as_ref();
        let effort_label = result
            .and_then(|r| r.reasoning_effort)
            .map(|eff| {
                let mut label = eff.to_string();
                if let Some(first) = label.get_mut(0..1) {
                    first.make_ascii_uppercase();
                }
                label
            })
            .unwrap_or_else(|| "default effort".to_string());

        let lines = vec![
            Line::from(
                format!(
                    "Model set to {} ({effort_label}).",
                    result
                        .as_ref()
                        .map(|r| r.model.as_str())
                        .unwrap_or("unchanged")
                )
                .bold(),
            ),
            Line::from("Press Enter to continue."),
        ];
        Paragraph::new(lines)
            .wrap(Wrap { trim: false })
            .render(area, buf);
    }
}

impl StepStateProvider for ModelSelectionWidget {
    fn get_step_state(&self) -> StepState {
        match self.status {
            ModelStepStatus::Hidden | ModelStepStatus::AwaitingCredentials => StepState::Hidden,
            ModelStepStatus::Loading
            | ModelStepStatus::Ready
            | ModelStepStatus::Saving
            | ModelStepStatus::Error(_) => StepState::InProgress,
            ModelStepStatus::Complete => StepState::Complete,
        }
    }
}

impl KeyboardHandler for ModelSelectionWidget {
    fn handle_key_event(&mut self, key_event: KeyEvent) {
        if key_event.kind != KeyEventKind::Press {
            return;
        }

        match key_event.code {
            KeyCode::Up if key_event.modifiers.is_empty() => match self.stage {
                SelectionStage::ModelList => self.move_model_selection(-1),
                SelectionStage::Reasoning(_) => self.move_reasoning_selection(-1),
            },
            KeyCode::Down if key_event.modifiers.is_empty() => match self.stage {
                SelectionStage::ModelList => self.move_model_selection(1),
                SelectionStage::Reasoning(_) => self.move_reasoning_selection(1),
            },
            KeyCode::PageUp if key_event.modifiers.is_empty() => match self.stage {
                SelectionStage::ModelList => self.move_model_selection_page(-1),
                SelectionStage::Reasoning(_) => self.move_reasoning_selection_page(-1),
            },
            KeyCode::PageDown if key_event.modifiers.is_empty() => match self.stage {
                SelectionStage::ModelList => self.move_model_selection_page(1),
                SelectionStage::Reasoning(_) => self.move_reasoning_selection_page(1),
            },
            KeyCode::Home if key_event.modifiers.is_empty() => {
                if matches!(self.stage, SelectionStage::ModelList) && !self.presets.is_empty() {
                    self.selected_index = 0;
                    self.adjust_model_scroll();
                    self.request_frame.schedule_frame();
                }
            }
            KeyCode::End if key_event.modifiers.is_empty() => {
                if matches!(self.stage, SelectionStage::ModelList) && !self.presets.is_empty() {
                    self.selected_index = self.presets.len() - 1;
                    self.adjust_model_scroll();
                    self.request_frame.schedule_frame();
                }
            }
            KeyCode::Esc if key_event.modifiers.is_empty() => {
                if matches!(self.stage, SelectionStage::Reasoning(_)) {
                    self.stage = SelectionStage::ModelList;
                    self.request_frame.schedule_frame();
                } else if matches!(self.status, ModelStepStatus::Error(_)) {
                    self.status = ModelStepStatus::Complete;
                    self.request_frame.schedule_frame();
                }
            }
            KeyCode::Enter if key_event.modifiers.is_empty() => match &self.status {
                ModelStepStatus::Ready => match self.stage {
                    SelectionStage::ModelList => self.begin_reasoning_stage(),
                    SelectionStage::Reasoning(_) => self.confirm_reasoning_selection(),
                },
                ModelStepStatus::Error(_) | ModelStepStatus::Complete => {
                    self.status = ModelStepStatus::Complete;
                    self.request_frame.schedule_frame();
                }
                _ => {}
            },
            _ => {}
        }
    }
}

impl WidgetRef for ModelSelectionWidget {
    fn render_ref(&self, area: Rect, buf: &mut Buffer) {
        Clear.render(area, buf);

        match &self.status {
            ModelStepStatus::Hidden | ModelStepStatus::AwaitingCredentials => {
                let lines = vec![
                    Line::from("Configure LiteLLM credentials first.").dim(),
                    Line::from("The model selector will appear afterwards."),
                ];
                Paragraph::new(lines)
                    .wrap(Wrap { trim: false })
                    .render(area, buf);
            }
            ModelStepStatus::Loading => self.render_loading(area, buf),
            ModelStepStatus::Ready => self.render_ready(area, buf),
            ModelStepStatus::Saving => {
                let lines = vec![
                    Line::from("Saving model selection…".bold()),
                    Line::from("Please wait."),
                ];
                Paragraph::new(lines)
                    .block(Block::default().borders(Borders::ALL))
                    .wrap(Wrap { trim: false })
                    .render(area, buf);
            }
            ModelStepStatus::Complete => self.render_completion(area, buf),
            ModelStepStatus::Error(message) => self.render_error(area, buf, message),
        }
    }
}
