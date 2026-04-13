#!/usr/bin/env bash
set -euo pipefail

CHANGELOG_PATH="${CHANGELOG_PATH:-agent_docs/CHANGELOG.md}"
version_input="${1:-Unreleased}"
version="${version_input#v}"

extract_section() {
  local section="$1"
  local header_bracket="## [$section]"
  local header_plain="## $section"
  awk -v header_bracket="$header_bracket" -v header_plain="$header_plain" '
    BEGIN {
      in_section = 0
    }
    function is_heading(line) {
      return line ~ /^## /
    }
    function matches_target(line) {
      return line == header_bracket || line == header_plain || index(line, header_bracket " -") == 1 || index(line, header_plain " -") == 1
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
