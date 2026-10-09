#!/bin/bash
# PostToolUse (Claude Code) hook: scripts/ 配下の .sh に実行権限を自動付与する
# 標準入力の JSON（tool_input.file_path）でファイルパスを渡す

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ] && echo "$FILE_PATH" | grep -qE '/scripts/[^/]+\.sh$'; then
    chmod +x "$FILE_PATH" 2>/dev/null || true
fi

echo '{}'
