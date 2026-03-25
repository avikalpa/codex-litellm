#!/usr/bin/env bash
set -euo pipefail

CHANGELOG_PATH="${CHANGELOG_PATH:-agent_docs/CHANGELOG.md}"
version_input="${1:-Unreleased}"
version="${version_input#v}"

extract_section() {
  local section="$1"
  awk -v section="$section" '
    BEGIN {
      in_section = 0
      wanted_bracket = "## [" section "]"
      wanted_plain = "## " section
    }
    function is_heading(line) {
      return line ~ /^## /
    }
    function matches_target(line) {
      return line == wanted_bracket || line == wanted_plain || line ~ ("^## " section "([[:space:]]+-|$)")
    }
    {
      if (!in_section) {
        if (matches_target($0)) {
          in_section = 1
          print
        }
        next
      }
      if (is_heading($0)) {
        exit
      }
      print
    }
  ' "$CHANGELOG_PATH"
}

if ! output="$(extract_section "$version")" || [ -z "$output" ]; then
  output=""
fi

if [ -z "$output" ] && [ "$version" != "Unreleased" ]; then
  output="$(extract_section Unreleased || true)"
fi

if [ -z "$output" ]; then
  echo "No changelog section found for $version or Unreleased in $CHANGELOG_PATH" >&2
  exit 1
fi

printf '%s\n' "$output"
