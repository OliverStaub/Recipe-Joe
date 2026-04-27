#!/usr/bin/env bash
# PostToolUse hook: format the file that Claude just edited.
# Reads JSON from stdin, extracts tool_input.file_path, and runs Prettier on it
# if it has a known extension and a Prettier executable can be located.
#
# Designed to be safe: never blocks the agent, never errors out, never logs noise.
set -u

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

# Try jq, then a python fallback so the hook still works on minimal images.
FILE=""
if command -v jq >/dev/null 2>&1; then
    FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)
elif command -v python3 >/dev/null 2>&1; then
    FILE=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin).get("tool_input",{})
    print(d.get("file_path") or d.get("path") or "")
except Exception:
    pass' 2>/dev/null || true)
fi

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

case "$FILE" in
    *.js|*.jsx|*.ts|*.tsx|*.svelte|*.json|*.jsonc|*.css|*.scss|*.html|*.md|*.mdx|*.yaml|*.yml) ;;
    *) exit 0 ;;
esac

# Prefer the project-local Prettier (respects project config + plugins like prettier-plugin-svelte).
# Fall back to a global Prettier if available. Either way, swallow output to keep the agent quiet.
if [ -x "./node_modules/.bin/prettier" ]; then
    ./node_modules/.bin/prettier --write --log-level silent "$FILE" >/dev/null 2>&1 || true
elif command -v prettier >/dev/null 2>&1; then
    prettier --write --log-level silent "$FILE" >/dev/null 2>&1 || true
fi

exit 0
