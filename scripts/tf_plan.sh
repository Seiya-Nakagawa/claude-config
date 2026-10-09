#!/bin/bash
# tf_plan.sh: Terraform の fmt → init → validate → plan を実行する（AI 実行用）。
# 任意のリポジトリ内から実行できる。plan のフル出力は $TF_DIR/tfplan.log に保存し、
# 標準出力にはサマリと変更内容のみを出力する。失敗時は生出力を stderr へ出す。
#
# 環境変数:
#   TF_DIR        Terraform ディレクトリ（リポジトリルートからの相対パス。既定: terraform）
#   TF_INIT_ARGS  terraform init へ追加する引数（例: -backend-config=env/stg-s3config.tfvars -reconfigure）
#   TF_PLAN_ARGS  terraform plan へ追加する引数（例: -var-file=env/stg.tfvars）
set -e

MAX_DIFF_LINES=200

ROOT=$(git rev-parse --show-toplevel)
TF_DIR="${TF_DIR:-terraform}"
WORK_DIR="$ROOT/$TF_DIR"

if [ ! -d "$WORK_DIR" ]; then
    echo "❌ Terraform ディレクトリが見つかりません: $WORK_DIR" >&2
    exit 1
fi

LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

# 失敗時のみ出力を表示する
run_quiet() {
    local label=$1
    shift
    if ! "$@" > "$LOG" 2>&1; then
        echo "❌ ${label} が失敗しました。" >&2
        cat "$LOG" >&2
        exit 1
    fi
}

run_quiet "fmt" terraform -chdir="$WORK_DIR" fmt -recursive -list=false
# shellcheck disable=SC2086
run_quiet "init" terraform -chdir="$WORK_DIR" init -input=false $TF_INIT_ARGS
run_quiet "validate" terraform -chdir="$WORK_DIR" validate -no-color

PLAN_LOG="$WORK_DIR/tfplan.log"
# shellcheck disable=SC2086
if ! terraform -chdir="$WORK_DIR" plan -input=false -no-color -out=tfplan $TF_PLAN_ARGS > "$PLAN_LOG" 2>&1; then
    echo "❌ plan が失敗しました。" >&2
    cat "$PLAN_LOG" >&2
    exit 1
fi

echo "=== Plan サマリー ==="
grep -E "^(Plan:|No changes)" "$PLAN_LOG" || true
echo "=== 変更内容 ==="
DIFF_LINES=$(grep -E "^\s*(# .* (will be|must be)|[+~-]|-/\+) " "$PLAN_LOG" | head -n "$MAX_DIFF_LINES" || true)
echo "${DIFF_LINES:-（変更なし）}"
echo "✅ Plan 完了。フル出力: $TF_DIR/tfplan.log"
