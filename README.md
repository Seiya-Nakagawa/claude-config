# claude-config

Claude Code のグローバル設定（`~/.claude/`）を管理するリポジトリ。
全リポジトリ共通の規約・スキル・サブエージェント・共通スクリプトを集約する。

## 管理対象

| パス | 内容 |
| ---- | ---- |
| `CLAUDE.md` | グローバル規約（全プロジェクト共通の基本方針） |
| `rules/` | 分野別の規約 |
| `skills/` | スキル（自動同期される `skills/synced/` は除く） |
| `agents/` | サブエージェント定義 |
| `scripts/` | hook・AI 実行用の共通スクリプト |

以下は `.gitignore` の許可リスト方式により管理対象外とする。

- 認証情報（`.credentials.json`）・履歴・セッション・キャッシュ
- `projects/`（証跡ログ・メモリ）
- `settings.json`（権限・hook・プラグイン設定）。接続先ホスト等の環境固有の情報を含み、
  Claude Code 自身が自動で書き換えるため、公開リポジトリでは管理しない。
  新しい端末ではプラグインと hook を下記「セットアップ」に従って再設定する

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

### hook

`~/.claude/settings.json` の `hooks` に以下を設定する。

```json
{
  "PreToolUse": [
    { "matcher": "Bash", "hooks": [
      { "type": "command", "command": "bash $HOME/.claude/scripts/block-protected-git-push.sh" } ] }
  ],
  "PostToolUse": [
    { "matcher": "Write|Edit", "hooks": [
      { "type": "command", "command": "bash $HOME/.claude/scripts/markdownlint-fix.sh" },
      { "type": "command", "command": "bash $HOME/.claude/scripts/chmod-shell-scripts.sh" } ] }
  ]
}
```

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
