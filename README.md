# claude-config

Claude Code のグローバル設定（`~/.claude/`）を管理するリポジトリ。
全リポジトリ共通の規約・スキル・サブエージェント・共通スクリプトを集約する。

## 管理対象

| パス | 内容 |
| ---- | ---- |
| `CLAUDE.md` | グローバル規約（全プロジェクト共通の基本方針） |
| `settings.json` | ユーザー設定（権限・hook・有効化するプラグイン） |
| `rules/` | 分野別の規約 |
| `skills/` | スキル（自動同期される `skills/synced/` は除く） |
| `agents/` | サブエージェント定義 |
| `scripts/` | hook・AI 実行用の共通スクリプト |

以下は `.gitignore` の許可リスト方式により管理対象外とする。

- 認証情報（`.credentials.json`）・履歴・セッション・キャッシュ
- `projects/`（証跡ログ・メモリ）

## セットアップ（新しい端末）

Claude Code を一度起動して `~/.claude/` を作成したうえで、既存ディレクトリに取り込む。

```bash
git -C ~/.claude init -b main
git -C ~/.claude remote add origin https://github.com/Seiya-Nakagawa/claude-config.git
git -C ~/.claude fetch origin
git -C ~/.claude reset --hard origin/main
git -C ~/.claude branch -u origin/main
```

- `reset --hard` は管理対象のファイルのみを上書きする。管理対象外（認証情報・履歴等）には影響しない

### プラグイン

公式マーケットプレイス（`claude-plugins-official`）から以下を user スコープで導入する。

```bash
for p in superpowers skill-creator claude-code-setup claude-md-management security-guidance \
  frontend-design playwright deploy-on-aws pyright-lsp terraform; do
  claude plugin install "$p@claude-plugins-official" --scope user
done
uv tool install pyright                               # pyright-lsp が使う pyright-langserver
docker pull hashicorp/terraform-mcp-server:0.4.0      # terraform プラグインの MCP サーバ
```

| プラグイン | 用途 |
| ---- | ---- |
| `pyright-lsp` | Python の型チェック・定義ジャンプ（Django・Lambda） |
| `terraform` | HashiCorp 公式 MCP。プロバイダ・モジュールの最新ドキュメント参照 |
| `claude-md-management` | `CLAUDE.md` の品質監査・セッションで得た知見の反映 |
| `security-guidance` | 編集時のセキュリティパターン警告 |
| `deploy-on-aws` | AWS 構成図・コスト見積り |
| `playwright` | 画面の動作確認 |

### セキュリティレビューの使い分け

| 手段 | 対象 | 用途 |
| ---- | ---- | ---- |
| `security-guidance`（プラグイン） | 編集中のコード | 編集時に危険なパターンを警告する |
| `/security-review`（公式コマンド） | 現在のブランチの差分 | PR 前の脆弱性レビュー。`origin/HEAD` が未設定のリポジトリでは `git remote set-head origin -a` が必要 |
| `security-auditor`（独自エージェント） | リポジトリ全体 | Terraform・GAS・Lambda 固有の観点と `rules/security.md` に基づく監査。公式にない観点のため残す |

## 規約の構成

公式の推奨（常時読み込む内容は最小限、手順はスキル、特定ファイルにのみ関係する規約は `paths` 指定）に沿って配置する。

| 種類 | 読み込まれるタイミング | 置き場所 |
| ---- | ---- | ---- |
| 原則・事実 | 毎セッション | `CLAUDE.md`、`paths` なしの `rules/*.md` |
| ファイル種別ごとの規約 | 該当ファイルの Read / Write / Edit 時 | `paths` 付きの `rules/*.md` |
| 手順 | 必要と判断したとき・`/スキル名` | `skills/` |
| 必ず守らせること | 常に（機械的に強制） | `scripts/` の hook |

## 運用

- 変更は他リポジトリと同じく PR ベースで行う（`rules/git-workflow.md`）
- **公開リポジトリである**。接続先ホスト・アカウント ID・顧客名等の環境固有の情報や機密情報は
  規約・スキルに書かず、プロジェクト個別の `CLAUDE.md` やメモリに置く
- `settings.json` の権限ルールで SSH 接続先を指定する場合は、IP アドレスではなく `~/.ssh/config` の
  ホスト別名（例: `ssh oci-server`）を使う
- `settings.json` は Claude Code 自身も書き換える（`/config`・プラグインの導入・権限の常時許可等）。
  コミット前に差分を確認し、機密情報や IP アドレスが混入していないことを確かめる
