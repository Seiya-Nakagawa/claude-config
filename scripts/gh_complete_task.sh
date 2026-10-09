#!/bin/bash

# GitHubプルリクエストのマージと後片付けを自動化するスクリプト

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 現在のブランチ名を取得
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# デフォルトブランチの取得（mainに固定）
DEFAULT_BRANCH="main"

# デフォルトブランチにいる場合は実行しない
if [ "$CURRENT_BRANCH" == "$DEFAULT_BRANCH" ]; then
    echo -e "${RED}エラー: デフォルトブランチ ($DEFAULT_BRANCH) 上で実行することはできません。${NC}"
    exit 1
fi

# 紐づくPRの情報を取得
PR_INFO=$(gh pr view "$CURRENT_BRANCH" --json number,state,baseRefName 2>/dev/null || echo "")

if [ -z "$PR_INFO" ]; then
    echo -e "${RED}エラー: 現在のブランチ ($CURRENT_BRANCH) に紐づくプルリクエストが見つかりません。${NC}"
    exit 1
fi

PR_NUMBER=$(echo "$PR_INFO" | grep -oP '"number":\K\d+')
PR_STATE=$(echo "$PR_INFO" | grep -oP '"state":"\K[^"]+')
BASE_BRANCH=$(echo "$PR_INFO" | grep -oP '"baseRefName":"\K[^"]+')

# PRがオープンでない場合はエラー
if [ "$PR_STATE" != "OPEN" ]; then
    echo -e "${RED}エラー: プルリクエスト #$PR_NUMBER は OPEN 状態ではありません。${NC}"
    exit 1
fi

# マージの実行（Squash固定）
gh pr merge "$PR_NUMBER" --squash --delete-branch

# まだ元のブランチにいる場合はベースブランチへ切り替え
# (gh pr merge -d は自動で切り替えることがあるが、念のため)
NEW_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$NEW_BRANCH" == "$CURRENT_BRANCH" ]; then
    git checkout "$BASE_BRANCH"
fi

# 最新をプル
git pull origin "$BASE_BRANCH"

# ローカルブランチがまだ残っている場合は削除
if git show-ref --verify --quiet "refs/heads/$CURRENT_BRANCH"; then
    git branch -d "$CURRENT_BRANCH" || {
        echo -e "${RED}警告: ローカルブランチの削除に失敗しました（未マージの変更がある可能性があります）。強制削除を試みます...${NC}"
        git branch -D "$CURRENT_BRANCH"
    }
fi

# リモートの追跡情報を更新
git remote prune origin

echo -e "${GREEN}完了しました！${NC}"
