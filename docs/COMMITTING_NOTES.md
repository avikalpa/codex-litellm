## Patch Commit Workflow

Keep the upstream checkout (`codex/`) pristine and record progress from the patch repository root. After each meaningful milestone (e.g. restoring a working TUI header, finishing LiteLLM onboarding wiring, or landing telemetry support), do the following:

1. **Capture in-flight upstream edits.** From `codex/`, use `git diff` to review changes. If you need a safety net before resetting, save them to a temporary patch file (e.g., `git diff > ../temp.patch`).
2. **Reset upstream to the tracked tag.** Run `git reset --hard <stable-tag>` inside `codex/` so the worktree matches the release baseline.
3. **Reapply the curated patch.** From `codex/`, run `git apply ../stable-tag.patch` (or any temporary patch saved in step 1) to restore the intended modifications.
4. **Verify the state.** Confirm `git status` is clean in `codex/` and the desired behavior still reproduces (build/tests as needed).
5. **Update the patch.** If new code is ready, regenerate `stable-tag.patch` with `git diff <stable-tag> > ../stable-tag.patch` and verify the diff captures only the intended changes.
6. **Commit from the patch repo.** In the repository root, stage the updated files (including `stable-tag.patch`, docs, and logs if relevant) and commit with a message that reflects the completed milestone. Treat “regenerated patch applies cleanly” as a milestone in its own right—always capture that state with `git commit` before moving on so future recoveries have a known-good checkpoint.

This loop keeps upstream history untouched while ensuring every checkpoint in `codex-litellm` corresponds to a reproducible patch.

## When the patch no longer applies

If `git apply ../stable-tag.patch` fails or the CLI suddenly looks identical to upstream (e.g., LiteLLM onboarding disappears), recover as follows:

1. **Confirm the baseline.** In `codex/`, run `git status -sb` and ensure `HEAD` points at the intended release tag (currently `rust-v0.53.0`). If you forgot which commit the patch targets, check the header of `stable-tag.patch` for the `index` lines.
2. **Locate the last patched commit.** Use `git reflog --date=iso` or inspect the `litellm/` branches to find the most recent commit that contained our LiteLLM changes.
3. **Restore the changes.** Either check out that commit to a temporary branch or cherry-pick it back onto the release tag (e.g., `git cherry-pick <sha>`). Verify `git status` is clean afterwards.
4. **Regenerate the patch.** From `codex/`, run `git diff <stable-tag> > ../stable-tag.patch` and doublecheck that the diff includes the expected LiteLLM files (onboarding model screen, telemetry, etc.).
5. **Update documentation as needed.** If the recovery required extra steps, capture them in `docs/` and add a short pointer in `AGENTS.md` so the workflow stays discoverable.

Running through these checks whenever the patch drifts prevents accidental work on an unmodified upstream tree.
