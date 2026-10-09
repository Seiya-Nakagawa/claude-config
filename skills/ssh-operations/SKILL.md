---
name: ssh-operations
description: >
  SSH でサーバーの状態確認・ログ収集・設定変更を行うときの手順と、作業証跡ログの保存先・書式。
  ssh コマンドを実行する前、サーバー作業の証跡を残すとき、証跡ログの保存先を確認するときに使用。
---

# SSH 操作ルール

## 基本方針

- **読み取り専用操作の優先**: サーバー状態確認・ログ収集は SSH で実施可能
- **変更作業の慎重性**: 設定変更は必要に応じて実施するが、必ず証跡を記録する
- **対話的セッションの回避**: 自動化可能なコマンドは Bash で実行する

## SSH コマンド実行パターン

### 1. 情報収集・確認（読み取り専用）

以下のコマンドは自由に実行可能：

```bash
# サーバー基本情報
ssh {host} "hostname && uname -a"
ssh {host} "whoami && pwd"

# ファイル・ディレクトリ確認
ssh {host} "ls -la /path/to/dir"
ssh {host} "cat /path/to/file"

# システム設定確認
ssh {host} "sudo systemctl status {service}"
ssh {host} "sudo systemctl cat {service}"
ssh {host} "sudo grep pattern /etc/config/file"

# ログ確認
ssh {host} "sudo tail -n 100 /var/log/file.log"

# ネットワーク・ファイアウォール
ssh {host} "sudo netstat -tlnp"
ssh {host} "sudo ufw status"
```

### 2. 設定変更作業

設定ファイル修正が必要な場合の流れ：

1. **変更前の状態を確認・記録**

   ```bash
   ssh {host} "sudo cat /etc/config/file" > backup_before.txt
   ```

2. **変更内容を確認してから実行**（必ず事前確認コマンドで現状確認）

   ```bash
   # 現状確認
   ssh {host} "sudo grep key /etc/config/file"
   # 変更実施（必要に応じて）
   ssh {host} "sudo sed -i.bak 's/old/new/g' /etc/config/file"
   # 変更確認
   ssh {host} "sudo grep key /etc/config/file"
   ```

3. **サービス再起動確認**

   ```bash
   ssh {host} "sudo systemctl restart {service}"
   ssh {host} "sudo systemctl status {service}"
   ```

## 証跡記録の方式

### ログの保存方法

情報収集で実施した複数のコマンド結果をまとめてログファイルに保存する場合：

```bash
# 複数コマンドの実行結果をファイルに保存
{
  echo "=== Command 1 ==="
  ssh {host} "command1"
  echo
  echo "=== Command 2 ==="
  ssh {host} "command2"
} > YYYY-MM-DD_operation.log 2>&1
```

### ログファイルの格納先

**対象は、AI がターミナルでコマンドを実行した場合の証跡に限る**。ブラウザ操作など
ターミナル実行を伴わない作業（GAS エディタでの手動操作等）はログ化の対象外とする。

証跡ログはリポジトリの一部ではなく、**WSL 上のローカルファイルとして保存し、Git では
管理しない**（プロジェクトのリポジトリ配下には置かない。`.gitignore` での除外でもなく、
そもそも別の場所に保存する）。

- **保存先**: `~/.claude/projects/{ワーキングディレクトリの "/" を "-" に置換したもの}/logs/{対象}/YYYY-MM-DD_作業内容.log`
  （例: `/home/seiya/git/{組織}/{リポジトリ}` での作業なら
  `~/.claude/projects/-home-seiya-git-{組織}-{リポジトリ}/logs/{対象}/2026-09-18_作業内容.log`）
- **ファイル命名**: 日付 + 作業内容（例：`2026-05-08_サーバー実状確認.log`）
- **内容**: 実行コマンド + 生出力（編集しない）
- 手順書・設計文書など、証跡ログ以外の文書は引き続き [document-standards.md](../../rules/document-standards.md)
  に従いプロジェクトの `docs/` 配下で Git 管理する

### ログ内容の構成

```text
========================================
[作業タイトル]
実行日時: YYYY-MM-DD
対象サーバ: ホスト名
========================================

## 1. [セクション1]

$ ssh {host} "command"
[出力結果]

## 2. [セクション2]

$ ssh {host} "command"
[出力結果]

========================================
## まとめ

[最終的な判定・結論]
```

## ベストプラクティス

### コマンド実行の順序

1. **読み取り専用コマンド** → 情報を確認して安全性を検証
2. **変更コマンド** → 本当に必要な場合のみ実行
3. **確認コマンド** → 変更が反映されたことを確認

### エラーハンドリング

- SSH 接続失敗時は、認証情報・ホスト名・ネットワークを確認
- コマンドエラーは生出力をログに残し、エラー内容を分析
- `--assumeno` フラグ（`dnf remove --assumeno` など）を活用して実行前に影響を確認

### 自動化の考慮

複数のサーバーで同じ作業が必要な場合は、スクリプト化を検討：

```bash
#!/bin/bash
SERVERS=("{host-a}" "{host-b}")
for server in "${SERVERS[@]}"; do
  echo "=== $server ==="
  ssh "$server" "command"
done
```

## セキュリティ考慮

- SSH キーの秘密鍵は `.ssh/` ディレクトリに保存し、`.gitignore` に追加
- パスワードを標準入力で渡さない（秘密鍵認証を使用）
- `sudo` が必要なコマンドは、事前に確認してから実行
- 機密情報（パスワード、トークン）がログに出力されないか確認
