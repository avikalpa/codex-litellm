# Committing Notes

## Purpose
This repo tracks a reproducible patchset, not an ad hoc fork. Commits should preserve that property.

## Milestone Commit Loop
1. Finish a coherent slice of work.
2. If code changed in `codex/`, regenerate `stable-tag.patch` from the pinned upstream baseline.
3. Verify the patched tree still builds.
4. Commit from the repo root with the patch, metadata, docs, and tests/log references that belong to that slice.
5. After the milestone commit, ask the user whether to publish now.

## Patch Discipline
- `codex/` is the editable upstream checkout.
- `stable-tag.patch` is the artifact the root repo preserves.
- A root commit that changes `codex/`-derived behavior without updating `stable-tag.patch` is incomplete.

## When Patch Apply Fails
1. Confirm which upstream tag or commit `codex/` is supposed to be on.
2. Reset only the `codex/` checkout to that baseline if needed.
3. Reapply `../stable-tag.patch`.
4. If it still fails, port the patch forward deliberately instead of forcing random hunks.
5. Rebuild, retest, and regenerate `stable-tag.patch`.

## Good Commit Content
- one logical milestone per commit
- updated patch when required
- updated docs when the operator workflow changed
- evidence logs referenced in `docs/CURRENT_TASK.md` when a bug was investigated live
