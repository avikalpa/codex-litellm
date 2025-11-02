## Patch Commit Workflow

Keep the upstream checkout (`codex/`) pristine and record progress from the patch repository root. After each meaningful milestone (e.g. restoring a working TUI header, finishing LiteLLM onboarding wiring, or landing telemetry support), do the following:

1. **Capture in-flight upstream edits.** From `codex/`, use `git diff` to review changes. If you need a safety net before resetting, save them to a temporary patch file (e.g., `git diff > ../temp.patch`).
2. **Reset upstream to the tracked tag.** Run `git reset --hard <stable-tag>` inside `codex/` so the worktree matches the release baseline.
3. **Reapply the curated patch.** From `codex/`, run `git apply ../stable-tag.patch` (or any temporary patch saved in step 1) to restore the intended modifications.
4. **Verify the state.** Confirm `git status` is clean in `codex/` and the desired behavior still reproduces (build/tests as needed).
5. **Update the patch.** If new code is ready, regenerate `stable-tag.patch` with `git diff <stable-tag> > ../stable-tag.patch` and verify the diff captures only the intended changes.
6. **Commit from the patch repo.** In the repository root, stage the updated files (including `stable-tag.patch`, docs, and logs if relevant) and commit with a message that reflects the completed milestone.

This loop keeps upstream history untouched while ensuring every checkpoint in `codex-litellm` corresponds to a reproducible patch.
