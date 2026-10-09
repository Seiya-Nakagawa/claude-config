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
  新しい端末では hook 設定（`scripts/` の呼び出し）を手動で再設定する

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

## 運用

- 変更は他リポジトリと同じく PR ベースで行う（`rules/git-workflow.md`）
- **公開リポジトリである**。接続先ホスト・アカウント ID・顧客名等の環境固有の情報や機密情報は
  規約・スキルに書かず、プロジェクト個別の `CLAUDE.md` やメモリに置く
