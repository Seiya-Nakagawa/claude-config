#!/bin/bash
# markdownlint-check.sh: 指定 .md ファイルの markdownlint チェックのみ実行する（--fix なし）。
# 違反があれば違反内容を stderr に出力し非ゼロ終了。違反がなければ完了の1行のみ出力。
set -e

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <file.md> [<file.md>...]" >&2
    exit 1
fi

LOG=$(mktemp)
if ! ~/.local/bin/markdownlint --config ~/.markdownlint.json "$@" > "$LOG" 2>&1; then
    cat "$LOG" >&2
    rm -f "$LOG"
    exit 1
fi
rm -f "$LOG"
echo "✅ markdownlint OK"
