#!/bin/bash
# tf_ssh_connect.sh: terraform output から接続先を解決し、パブリック IP へ SSH 接続する（ユーザー実行用）。
# 任意のリポジトリ内から実行できる。
#
# 環境変数:
#   TF_DIR              Terraform ディレクトリ（リポジトリルートからの相対パス。既定: terraform）
#   TF_OUTPUT_IP        接続先 IP の output 名（既定: instance_public_ip）
#   TF_OUTPUT_USER      接続ユーザーの output 名（既定: instance_user。無ければ $USER）
#   SSH_PRIV_KEY_FILE   SSH 秘密鍵のパス（既定: ~/.ssh/id_rsa。-i で上書き可）
set -e

TF_DIR="${TF_DIR:-terraform}"
TF_OUTPUT_IP="${TF_OUTPUT_IP:-instance_public_ip}"
TF_OUTPUT_USER="${TF_OUTPUT_USER:-instance_user}"
SSH_PRIV_KEY_FILE="${SSH_PRIV_KEY_FILE:-$HOME/.ssh/id_rsa}"

show_help() {
    echo "Usage: $0 [-i <key_path>] [-d <tf_dir>] [-h]"
    echo "  -i <key_path>  SSH 秘密鍵のパス (既定: $SSH_PRIV_KEY_FILE)"
    echo "  -d <tf_dir>    Terraform ディレクトリ (リポジトリルートからの相対パス。既定: $TF_DIR)"
    echo "  -h             このヘルプを表示する"
}

while getopts "i:d:h" opt; do
    case "$opt" in
        i) SSH_PRIV_KEY_FILE=$OPTARG ;;
        d) TF_DIR=$OPTARG ;;
        h) show_help; exit 0 ;;
        *) show_help; exit 1 ;;
    esac
done

if [ ! -f "$SSH_PRIV_KEY_FILE" ]; then
    echo "Error: SSH 秘密鍵が見つかりません: $SSH_PRIV_KEY_FILE" >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq がインストールされていません。" >&2
    exit 1
fi

WORK_DIR="$(git rev-parse --show-toplevel)/$TF_DIR"
if [ ! -d "$WORK_DIR" ]; then
    echo "Error: Terraform ディレクトリが見つかりません: $WORK_DIR" >&2
    exit 1
fi

echo "[1/2] terraform output から接続情報を取得中... (Dir: $WORK_DIR)"
TF_OUTPUT=$(terraform -chdir="$WORK_DIR" output -json)

INSTANCE_IP=$(echo "$TF_OUTPUT" | jq -r --arg k "$TF_OUTPUT_IP" '.[$k].value // empty')
OS_USERNAME=$(echo "$TF_OUTPUT" | jq -r --arg k "$TF_OUTPUT_USER" --arg d "$USER" '.[$k].value // $d')

if [ -z "$INSTANCE_IP" ]; then
    echo "Error: terraform output に $TF_OUTPUT_IP が見つかりません。" >&2
    exit 1
fi

echo "[2/2] SSH 接続を開始します: ${OS_USERNAME}@${INSTANCE_IP} (Key: $SSH_PRIV_KEY_FILE)"
ssh -i "$SSH_PRIV_KEY_FILE" "${OS_USERNAME}@${INSTANCE_IP}"
