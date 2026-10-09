---
paths:
  - "**/ansible/**"
  - "**/playbooks/**"
  - "**/roles/**"
  - "**/ansible.cfg"
---

# Ansible 規約

全リポジトリ共通の Ansible 運用規約。
インベントリ・ロール構成・接続先の解決方法・実行スクリプトなど、
**リポジトリ固有の値はプロジェクト個別の `CLAUDE.md` に従う**。
Terraform でインスタンスを作成したうえで Ansible で構成する 2 段構成の場合、
Terraform 側の運用は [terraform.md](terraform.md) に従う。

## 1. 実行担当の分担

- **AI**: Playbook・ロールの編集、ドライラン（`--check`）の実行と結果の提示、
  ユーザー承認後の適用実行
- **ユーザー**: ドライラン結果の確認と適用の承認／却下、Vault パスワードの配置

## 2. 作業順序

1. AI: Playbook・ロール・テンプレートを編集する
2. AI: `--check`（ドライラン）で影響範囲を確認する
3. AI: ドライラン結果から変更されるタスクの要約をユーザーへ提示する
4. ユーザー: 適用を承認する
5. AI: 承認後、適用を実行する
6. AI: 適用結果を報告し、必要に応じて状態を確認する
   （SSH 経由の確認は [ssh-operations スキル](../skills/ssh-operations/SKILL.md) に従う）

- 変更を伴う実行は、必ず事前に `--check` で影響範囲を確認する
- ロール単位で流す場合は、ロール名と同名のタグ（`--tags {ロール名}`）を使用する
- Ansible のタスクは冪等に書き、再実行しても状態が変わらないようにする

## 3. 機密情報

- パスワード等の機密情報は Ansible Vault で暗号化する（[security.md](security.md) 参照）
- Vault パスワードは Git 管理外のファイルに置き、`ansible.cfg` の `vault_password_file` で参照する。
  実行時にオプションで指定しなくてよい状態にする
- Vault パスワードファイルの内容を出力・ログへ残さない
