#!/bin/bash
# OCI Bastion CI/CD 用 GitHub Secrets 登録（ユーザー実行用）
#
# GitHub Actions から OCI Bastion の Managed SSH Session を作成するための秘密鍵
# （BASTION_OCI_PRIVATE_KEY）を指定リポジトリへ登録する。CI/CD 専用 IAM ユーザーの
# OCID・フィンガープリントは秘密情報ではないため、呼び出し側のリポジトリのコードに
# 直接定義し、Secrets としては扱わない。
#
# GitHub Actions の Secrets は個人アカウント配下ではリポジトリ単位の登録以外に
# 共有手段がないため、複数リポジトリで同一の CI/CD 専用 IAM ユーザーを使い回す際、
# このスクリプトで登録の手間を共通化する。

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <owner/repo> <private_key_file>" >&2
    exit 1
fi

REPO="$1"
KEY_FILE="$2"

if [ ! -f "$KEY_FILE" ]; then
    echo "Error: 秘密鍵ファイルが見つかりません: $KEY_FILE" >&2
    exit 1
fi

gh secret set BASTION_OCI_PRIVATE_KEY --repo "$REPO" < "$KEY_FILE"

echo "✅ ${REPO} へ BASTION_OCI_PRIVATE_KEY を登録しました。"
