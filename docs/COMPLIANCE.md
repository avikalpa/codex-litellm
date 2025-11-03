# Compliance & Attribution Guidelines

This document captures the low-noise licensing and attribution rules for the
`codex-litellm` patch set. It exists so we can publish binaries with confidence
and keep the legal story consistent across future contributors.

---

## 1. Licensing Baseline

- Repository and release artifacts are covered by the **Apache License 2.0**.
- Upstream `openai/codex` is also Apache-2.0 — keep upstream attribution intact.
- We do **not** add extra usage restrictions or marketing copy. Stick to factual,
  quiet wording throughout the project.

Author credit (for the patch set and new files):

```
Avikalpa Kundu <avi@gour.top>
```

---

## 2. Core Files in the Repo Root

| File     | Requirement |
| -------- | ----------- |
| `LICENSE` | Exact Apache-2.0 text, unmodified. |
| `NOTICE`  | Lists the upstream codex project and summarizes the major changes we ship (LiteLLM integration, packaging, telemetry). Reference `LICENSE` for the legal text. |

### Quick Checks
- `LICENSE` must remain byte-for-byte the standard Apache-2.0 grant.
- `NOTICE` should stay short, professional, and unaffiliated (“no endorsement implied”).

---

## 3. Source File Headers & SPDX

Use headers to make provenance scanners happy without drowning the codebase.

| Scenario | Header style |
| -------- | ------------ |
| New source files we author (Rust/TS/JS/sh etc.) | Full Apache header. |
| Upstream files with substantial modifications | Upstream header **plus** a one-line “Modifications by …” trailer. |
| Tiny helper scripts where a full block is noisy | SPDX two-liner. |
| Generated data / JSON / patches | No extra header. |

**Full header (default):**
```text
// Copyright (c) 2025 Avikalpa Kundu <avi@gour.top>
// Licensed under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0
// See the NOTICE file distributed with this work for attribution details.
```

**SPDX short form (tiny scripts):**
```text
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Avikalpa Kundu <avi@gour.top>
```

**Optional trailer for heavily modified upstream files:**
```text
// Modifications by Avikalpa Kundu: LiteLLM-native integration (2025-11-03).
```

---

## 4. README & Docs Tone

In the README “Licensing” section:
- State that both the repository and releases are Apache-2.0.
- Mention that upstream codex is Apache-2.0.
- Point to `NOTICE` for attribution.
- Close with the unaffiliated disclaimer (“No endorsement implied.”)

Avoid dedicated acknowledgements sections or marketing language elsewhere.

Documentation should link back to this compliance note whenever process steps
depend on it (e.g., AGENTS.md, publishing guides).

---

## 5. Distribution Artifacts

Every binary package we ship **must** contain `LICENSE` and `NOTICE`.

Current build tooling already enforces this:

- `build.sh` copies both files into each `dist/codex-litellm-*.tar.gz`.
- `scripts/package-openwrt.sh` installs them into
  `/usr/share/licenses/codex-litellm/`.
- `scripts/package-termux.sh` installs them into
  `/usr/share/doc/codex-litellm/`.

If we add new packaging targets, wire the same copy step into those scripts.

---

## 6. Release Checklist

Before tagging / uploading a release:

1. `LICENSE` present and untouched.
2. `NOTICE` lists upstream codex and our modifications.
3. New or heavily modified source files carry the right header/SPDX lines.
4. README licensing section matches the wording in §4.
5. Archived artifacts (`tar.gz`, `zip`, etc.) include `LICENSE` + `NOTICE`.
6. Platform packages install the files under `/usr/share/doc` or
   `/usr/share/licenses` as appropriate.
7. `codex-litellm --version` (or release notes) can mention
   “See NOTICE for attributions.” (Optional but encouraged.)
8. CI / tests pass on the staged commit.

Log the completion of this checklist in `TASK.md` for traceability.

---

## 7. Non-Goals

- Do **not** add extra credit clauses or usage limitations.
- Do **not** introduce vendor/trademark references beyond what upstream already
  uses.
- Keep acknowledgements muted; attribution lives in NOTICE, headers, and
  high-level release notes.

Follow these rules and the project stays Apache-clean while giving proper credit
to upstream and the LiteLLM patch authors.
