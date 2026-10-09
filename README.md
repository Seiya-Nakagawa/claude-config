# claude-config

Claude Code のグローバル設定（`~/.claude/`）を管理するリポジトリ。
全リポジトリ共通の規約・スキル・サブエージェント・共通スクリプトを集約する。

## 管理対象

| パス | 内容 |
| ---- | ---- |
| `CLAUDE.md` | グローバル規約（全プロジェクト共通の基本方針） |
| `settings.json` | Claude Code のユーザー設定（権限・hook・プラグイン） |
| `rules/` | 分野別の規約 |
| `skills/` | スキル（自動同期される `skills/synced/` は除く） |
| `agents/` | サブエージェント定義 |
| `scripts/` | hook・AI 実行用の共通スクリプト |

認証情報（`.credentials.json`）・履歴・セッション・キャッシュ・`projects/`（証跡ログ・メモリ）は
`.gitignore` の許可リスト方式により管理対象外とする。

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
- `settings.json` は Claude Code 自身も書き換えるため（`/config`・権限の許可等）、
  差分が出ていないか作業前に `git -C ~/.claude status` で確認する
