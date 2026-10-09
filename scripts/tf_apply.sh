#!/bin/bash
# tf_apply.sh: tf_plan.sh が保存した実行計画（$TF_DIR/tfplan）を適用する（AI 実行用）。
# 標準出力には適用結果のサマリのみを出力する。失敗時は生出力を stderr へ出す。
# 実行計画は適用の成否にかかわらず再利用防止のため削除する。
#
# 環境変数:
#   TF_DIR  Terraform ディレクトリ（リポジトリルートからの相対パス。既定: terraform）
set -e

ROOT=$(git rev-parse --show-toplevel)
TF_DIR="${TF_DIR:-terraform}"
WORK_DIR="$ROOT/$TF_DIR"

if [ ! -f "$WORK_DIR/tfplan" ]; then
    echo "❌ 実行計画ファイル ($TF_DIR/tfplan) が見つかりません。先に tf_plan.sh を実行してください。" >&2
    exit 1
fi

LOG=$(mktemp)
trap 'rm -f "$LOG" "$WORK_DIR/tfplan"' EXIT

if ! terraform -chdir="$WORK_DIR" apply -input=false -no-color tfplan > "$LOG" 2>&1; then
    echo "❌ apply が失敗しました。" >&2
    cat "$LOG" >&2
    exit 1
fi

grep -E "^(Apply complete!|.* (Creation|Modifications|Destruction) complete)" "$LOG" || true
echo "✅ 適用が完了しました。"
