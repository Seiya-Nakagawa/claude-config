#!/bin/bash
# hook（PreToolUse / Bash）: main への直接 push と force push をブロックする
# Claude Code が標準入力で渡す JSON の tool_input.command と cwd を読む。
# ブロック時は理由を stderr に出力し exit 2 で終了する（Claude にツール実行の拒否として伝わる）
set -e

PROTECTED_BRANCH_PATTERN='^(main|master)$'

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
CWD=$(jq -r '.cwd // empty' <<<"$INPUT")

# コマンドの位置（行頭、; & | ( の直後）にある git push のみを対象とする
# ヒアドキュメントや文字列中で git push に言及しているだけのコマンドを誤検知しないため
GIT_PUSH_PATTERN='(^|[;&|(])[[:space:]]*git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]][^;&|]*)?$|(^|[;&|(])[[:space:]]*git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]][^;&|]*)?[;&|]'
if ! grep -qE "$GIT_PUSH_PATTERN" <<<"$COMMAND"; then
    exit 0
fi

# 判定対象を git push の引数部分（次の ; & | まで）に限定し、コミットメッセージ等の誤検知を防ぐ
PUSH_SEGMENT=$(grep -oE '(^|[;&|(])[[:space:]]*git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]][^;&|]*)?' <<<"$COMMAND" | head -n 1)

block() {
    echo "🚫 $1" >&2
    echo "git-workflow.md 6章により禁止されている操作です。必要な場合はユーザー自身が \`! <command>\` で実行してください。" >&2
    exit 2
}

# force push（--force / --force-with-lease / -f / +refspec）
if grep -qE '[[:space:]](--force|--force-with-lease|-f)([[:space:]=]|$)|[[:space:]]\+[^[:space:]]+' <<<"$PUSH_SEGMENT"; then
    block "force push はブロックされました。"
fi

# 明示的な main への push（origin main、HEAD:main 等）
if grep -qE '[[:space:]](origin[[:space:]]+)?([^[:space:]]+:)?(main|master)([[:space:]]|$)' <<<"$PUSH_SEGMENT"; then
    block "main への直接 push はブロックされました。"
fi

# 引数なしの git push は、現在のブランチが main なら main への push になる
# git -C <path> 指定がある場合はそのパスで判定する
REPO_DIR=$(grep -oE 'git[[:space:]]+-C[[:space:]]+[^[:space:]]+' <<<"$PUSH_SEGMENT" | head -n 1 | awk '{print $3}')
REPO_DIR=${REPO_DIR/#\~/$HOME}
REPO_DIR=${REPO_DIR:-$CWD}
if [ -n "$REPO_DIR" ]; then
    BRANCH=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || true)
    if grep -qE "$PROTECTED_BRANCH_PATTERN" <<<"$BRANCH"; then
        block "現在のブランチ（$BRANCH）からの push はブロックされました。作業ブランチを作成してください。"
    fi
fi

exit 0
