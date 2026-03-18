# Compliance

## License Split
- Software and software-adjacent repository contents remain under Apache-2.0:
  - code
  - patches
  - build/release scripts
  - package metadata
  - packaged release artifacts
- Prose documentation is under CC BY 4.0:
  - `AGENTS.md`
  - `agent_docs/`
- Upstream `openai/codex` remains Apache-2.0. Keep upstream attribution intact.

## Root Files
- `LICENSE` must remain the standard Apache-2.0 text.
- `LICENSE-docs-CC-BY-4.0.txt` carries the documentation license text.
- `NOTICE` should identify upstream Codex and summarize our major software modifications factually.

## Source Headers
- New authored source files should carry Apache-2.0/SPDX headers as appropriate.
- Heavily modified upstream files should preserve upstream provenance and may add a short modifications trailer.
- Markdown documentation does not need per-file headers if the repo-level docs license remains explicit.
- Generated data, JSON, and patch files do not need extra headers.

## Distribution Rule
- Every shipped software artifact must include `LICENSE` and `NOTICE`.
- Source distributions or repository mirrors that include the docs should also retain `LICENSE-docs-CC-BY-4.0.txt`.

## Documentation Rule
- Keep attribution factual and low-noise.
- Do not imply endorsement by upstream.
- Keep the code/docs license boundary explicit in the README and compliance notes.
