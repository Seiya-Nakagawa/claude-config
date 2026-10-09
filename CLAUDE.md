# CLAUDE.md

このファイルは、Claude Codeのグローバルガイダンスです。

## 1. 全体方針

- 文字コード: **UTF-8**
- 改行コード: **LF**
- 言語：日本語を基本とする。変数名・関数名などのコード識別子は英語を使用する
- **AIの応答は日本語で行う**

## 2. 機密情報の取り扱い

- APIキー、パスワード、接続情報などの機密情報は、コード内に直接記述することを**厳禁**とする
- 機密情報は環境変数（`.env` ファイルなど）で管理し、`.gitignore` に追加してリポジトリにコミットしない
- `.env`、`credentials.json`、`*.pem`、`*.key` などのファイルは絶対にコミットしない
- IaC・サーバーレス構成における具体的な扱いは [~/.claude/rules/security.md](rules/security.md) に従う

## 3. AI 利用規約

- AIとのコミュニケーションおよびAIからの応答は**日本語**で行う
- 作業内容に合わせて該当するスキルの `SKILL.md` を読み込み、その一気通貫フローを遵守する
- **ファイルの変更内容は、チャット上の応答だけで把握できるように提示する**。
  「〇〇を修正しました」で済ませず、変更差分（追加・削除・変更点）を要約して本文中に示す。
  ユーザーがファイルを開くのは、詳細を自分で確認したいときに限る
- **共通規約は本グローバル規約および `~/.claude/rules/` 配下で一元管理する**。
  プロジェクト個別の `CLAUDE.md` には、そのリポジトリ固有の事情のみを記載する（第5章参照）
- ユーザーから修正指示があった場合、それが永続的な規約（`CLAUDE.md`, `.claude`配下 等）に反映すべき内容かを確認し、必要であれば規約自体を更新する
- `.claude/rules/` 配下のルールを更新した場合、対応するスキルが存在すればその `SKILL.md` も同時に更新する
- 規約から参照するファイル・スキルは、参照先が実在することを確認する。リンク切れの参照を残さない
- プロジェクト配下の `.claude/` のファイル（settings, rules, skills 等）に変更がある場合は、対応中のブランチに含めてコミットする。
  グローバル設定（`~/.claude/`）の変更は [git-workflow.md](rules/git-workflow.md) 7章に従う

## 4. 各種規約

作業内容に応じて、以下のルールファイルを読み込み、その指示に従うこと。

- **Git 運用規約**: [~/.claude/rules/git-workflow.md](rules/git-workflow.md) — **全変更で必読**。PR ベースの運用、`main` 直接プッシュ禁止、リリース方針（デプロイ・動作確認 → PR → CI → マージ → CD）、承認フロー
- **コーディング規約**: [~/.claude/rules/coding-standards.md](rules/coding-standards.md) — 言語別のスタイル、リンター、命名規則
- **ログ出力規約**: [~/.claude/rules/logging.md](rules/logging.md) — ログレベルの使い分け、出力時の注意点
- **Markdown 記法**: [~/.claude/rules/markdown.md](rules/markdown.md) — markdownlint 準拠
- **ドキュメント体系**: [~/.claude/rules/document-standards.md](rules/document-standards.md) — 要件定義 / 基本設計 / 詳細設計のスコープ定義。**全プロジェクトで要件定義書・基本設計書の作成を必須とする**。インフラ管理プロジェクトは基本設計書を分野ごとの章立てに分割する
- **ドキュメント同期**: [~/.claude/rules/docs-sync.md](rules/docs-sync.md) — コード変更時のドキュメント更新
- **セキュリティ規約**: [~/.claude/rules/security.md](rules/security.md) — 機密情報の管理、IaC / サーバーレスでの扱い、AI による本番操作
- **シェル操作・スクリプト規約**: [~/.claude/rules/shell-operations.md](rules/shell-operations.md) — コマンド実行方針、スクリプトの出力ポリシー、実行権限
- **SSH 操作規約**: [~/.claude/rules/ssh-operations.md](rules/ssh-operations.md) — SSH コマンド実行、証跡記録、サーバー作業の流れ
- **Terraform 規約**: [~/.claude/rules/terraform.md](rules/terraform.md) — plan / apply の担当分担、tf ファイル分割、環境ごとの適用方針、標準スクリプト
- **Ansible 規約**: [~/.claude/rules/ansible.md](rules/ansible.md) — 実行担当の分担、ドライラン先行の作業順序、Vault による機密情報管理
- **AWS Lambda 規約**: [~/.claude/rules/lambda.md](rules/lambda.md) — IaC との責務分担、デプロイフロー、CLI 動作確認
- **Python 規約**: [~/.claude/rules/python.md](rules/python.md) — サーバーレス関数アプリの構成・実装方針・テスト
- **GAS デプロイ**: [~/.claude/rules/gas-deploy-flow.md](rules/gas-deploy-flow.md) — Google Apps Script のデプロイフロー、デプロイメント ID の固定化

## 5. プロジェクト個別規約（`CLAUDE.md`）

**共通規約は本グローバル規約および `~/.claude/rules/` 配下で一元管理する。**
プロジェクト個別の `CLAUDE.md` には、そのリポジトリ固有の事情のみを記載する。

### 5.1. 記載しない（グローバルで管理する）

以下は本グローバル規約および第4章のルールファイルでカバーされるため、プロジェクト側に重複定義しない。

- 基本方針（文字コード、改行コード、使用言語、AI の応答言語）
- 機密情報の取り扱いに関する一般方針
- Git 運用（ブランチ戦略、コミットメッセージ、プッシュ、PR、Milestone）
- コーディング規約、ログ出力規約、Markdown 記法
- ドキュメント体系・ドキュメント同期の一般ルール
- セキュリティ規約（機密情報の管理、IaC / サーバーレスでの扱い、AI による本番操作の原則）
- シェル操作・スクリプト規約、SSH 操作規約
- Terraform / AWS Lambda / Python / GAS の一般的な作業フロー・デプロイ手順
- スキル（`SKILL.md`）・サブエージェント定義。実体は `~/.claude/skills/`・`~/.claude/agents/` に集約し、
  プロジェクト配下（`.claude/skills/`・`.claude/agents/`）に複製しない

グローバル規約と矛盾する記述をプロジェクト側に見つけた場合は削除する。
プロジェクト単位で例外を設ける必要が生じた場合も、プロジェクト側に書かず、
**グローバル規約側に例外条件として追記する**。

### 5.2. 記載する（プロジェクト固有）

- リポジトリ構成、コンポーネントの責務、アーキテクチャ上の注意点
- 固有の識別子・設定値（GAS のスクリプト ID / デプロイ ID、公開 URL、スクリプトプロパティ名 等）
- 固有のコマンド（ビルド、テスト、デプロイスクリプト）
- 固有の運用手順、既知の落とし穴・回避策
- 参照すべきドキュメントへのリンク

判断基準は「そのリポジトリを他リポジトリに置き換えても同じことが言えるなら、それはグローバル規約である」。

### 5.3. 冒頭の定型文

プロジェクト個別ファイルの冒頭には以下を記載し、参照先を明示する。

```markdown
# CLAUDE.md

このファイルは、本リポジトリ固有の事情を記録したものです。

基本方針・機密情報の取り扱い・Git 運用・コーディング規約・Markdown 記法などの共通規約は
グローバル規約（`~/.claude/`）に従います。
**本ファイルに共通規約を重複定義しないこと。**
```

固有の事情が存在しないリポジトリでは、上記の定型文のみのファイルとする。
