#!/bin/bash
# PostToolUse (Claude Code) hook: 編集した .md に markdownlint --fix を実行する
# 標準入力の JSON（tool_input.file_path）でファイルパスを渡す

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -n "$FILE_PATH" ] && [[ "$FILE_PATH" == *.md ]] && [ -f "$FILE_PATH" ]; then
    ~/.local/bin/markdownlint --config ~/.markdownlint.json --fix "$FILE_PATH" > /dev/null 2>&1 || true
fi

echo '{}'
