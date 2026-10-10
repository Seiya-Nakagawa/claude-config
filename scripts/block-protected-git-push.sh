#!/bin/bash
# hook（PreToolUse / Bash）: main への直接 push と force push をブロックする
# Claude Code が標準入力で渡す JSON の tool_input.command と cwd を読む。
# ブロック時は理由を stderr に出力し exit 2 で終了する（Claude にツール実行の拒否として伝わる）
#
# 文字列照合によるガードレールであり、意図的な回避までは防げない。
# 最終的な防御は GitHub 側の Ruleset（デフォルトブランチの PR 必須・force push 禁止）が担う
set -e

PROTECTED_BRANCHES='main|master'

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
CWD=$(jq -r '.cwd // empty' <<<"$INPUT")

# git push の出現位置: 行頭、; & | ( の直後、引用符の直後（bash -c "git push" 等）
# バッククォートは Markdown のコード表記と区別できず誤検知が多いため含めない（$(...) は ( で検出する）
BOUNDARY='(^|[;&|("'\''])[[:space:]]*'
# 前置き: env / command / exec / nohup / time / sudo と、環境変数の代入（FOO=1）
PREFIX='((env|command|exec|nohup|time|sudo)[[:space:]]+|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
# git のグローバルオプション: -C <path>、-c <key=val>、--git-dir=<path> 等
GIT_OPTS='([[:space:]]+(-C|-c|--git-dir|--work-tree|--namespace)[[:space:]]+[^[:space:]]+|[[:space:]]+-[^[:space:]]+)*'
PUSH_PATTERN="${BOUNDARY}${PREFIX}git${GIT_OPTS}[[:space:]]+push([[:space:]][^;&|]*)?"

if ! grep -qE "$PUSH_PATTERN" <<<"$COMMAND"; then
    exit 0
fi

# 判定対象を git push の引数部分（次の ; & | まで）に限定し、コミットメッセージ等の誤検知を防ぐ
PUSH_SEGMENT=$(grep -oE "$PUSH_PATTERN" <<<"$COMMAND" | head -n 1)
# push 以降の引数のみ（グローバルオプションの -c 等を force 判定に含めないため）
PUSH_ARGS=$(sed -E 's/^.*[[:space:]]push([[:space:]]|$)/ /' <<<"$PUSH_SEGMENT")

block() {
    echo "🚫 $1" >&2
    echo "git-workflow.md 6章により禁止されている操作です。必要な場合はユーザー自身が \`! <command>\` で実行してください。" >&2
    exit 2
}

# force push: --force / --force-with-lease / --force-if-includes、-f を含む短縮オプション（-uf 等）、+refspec
if grep -qE '[[:space:]](--force[-a-z]*|-[A-Za-z]*f[A-Za-z]*)([[:space:]=]|$)|[[:space:]]\+[^[:space:]]+' <<<"$PUSH_ARGS"; then
    block "force push はブロックされました。"
fi

# 全ブランチを対象にする push（main を含む）
if grep -qE '[[:space:]](--all|--mirror)([[:space:]]|$)' <<<"$PUSH_ARGS"; then
    block "--all / --mirror による push はブロックされました。"
fi

# 明示的な main への push: main、HEAD:main、refs/heads/main、引用符付き
if grep -qE "([[:space:]:]|[[:space:]][\"'])(refs/heads/)?(${PROTECTED_BRANCHES})[\"']?([[:space:]]|\$)" <<<"$PUSH_ARGS"; then
    block "main への直接 push はブロックされました。"
fi

# リモートブランチの削除（--delete / -d / :branch）は現在のブランチに依存しないため許可する
# main 自体の削除は上の明示的な main への push の判定でブロック済み
if grep -qE '[[:space:]](--delete|-d)([[:space:]]|$)|[[:space:]]:[^[:space:]]+' <<<"$PUSH_ARGS"; then
    exit 0
fi

# 引数なしの git push は、現在のブランチが main なら main への push になる
# git -C <path> 指定がある場合はそのパスで判定する
REPO_DIR=$(grep -oE -- '-C[[:space:]]+[^[:space:]]+' <<<"$PUSH_SEGMENT" | head -n 1 | awk '{print $2}' | tr -d "\"'")
REPO_DIR=${REPO_DIR/#\~/$HOME}
REPO_DIR=${REPO_DIR:-$CWD}
if [ -n "$REPO_DIR" ]; then
    BRANCH=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || true)
    if grep -qE "^(${PROTECTED_BRANCHES})\$" <<<"$BRANCH"; then
        block "現在のブランチ（$BRANCH）からの push はブロックされました。作業ブランチを作成してください。"
    fi
fi

exit 0
