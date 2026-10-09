# シェル操作規約

全リポジトリ共通の、AI がシェルコマンドを実行する際の方針。
SSH 越しの操作は [ssh-operations スキル](../skills/ssh-operations/SKILL.md) に従う。

## 1. コマンド実行の基本方針

- **リポジトリ同梱のスクリプトは直接実行する**: `bash` コマンドや `source` コマンドを付けず、
  `./scripts/xxx.sh` のように直接実行する
- **`cd` を使わずフルパスで実行する**: ディレクトリ移動は行わず、`git -C <path>` や絶対パス指定で
  コマンドを実行する。スクリプトはリポジトリルートから `./scripts/xxx.sh` で実行する
- `cd dir && command` のように `cd` を他のコマンドと連結しない

## 2. 実行順序

1. **読み取り専用コマンド** → 情報を確認して安全性を検証する
2. **変更コマンド** → 本当に必要な場合のみ実行する
3. **確認コマンド** → 変更が反映されたことを確認する

## 3. シェルスクリプトの作成

シェルスクリプトの出力方針・作成ルール・実行権限は [shell-scripting.md](shell-scripting.md) に従う

## 4. グローバル共通スクリプト

リポジトリを問わず使う汎用スクリプトは `~/.claude/scripts/` に置き、各リポジトリの `scripts/` には
複製しない。リポジトリ固有の値（アカウント ID・ディレクトリ構成等）を持つスクリプトのみ
リポジトリ側に置く。

| スクリプト | 用途 |
| ---- | ---- |
| `markdownlint-fix.sh` | hook。編集した `.md` に `markdownlint --fix` を実行する |
| `chmod-shell-scripts.sh` | hook。`scripts/` 配下の `.sh` に実行権限を付与する |
| `block-protected-git-push.sh` | hook（PreToolUse）。`main` への直接 push と force push をブロックする |
| `markdownlint-check.sh` | `.md` の markdownlint チェック（`--fix` なし）。AI が編集後の確認に使う |
| `gh_complete_task.sh` | 現在のブランチの PR を squash マージし、ブランチを片付ける |
| `tf_plan.sh` | Terraform の `fmt` → `init` → `validate` → `plan` を実行する（AI 実行用。[terraform.md](terraform.md) 10章） |
| `tf_apply.sh` | `tf_plan.sh` が保存した実行計画を適用する（AI 実行用。[terraform.md](terraform.md) 10章） |
| `tf_ssh_connect.sh` | `terraform output` から接続先を解決して SSH 接続する（ユーザー実行用。[terraform.md](terraform.md) 10章） |
| `gh_secret_set_oci_bastion.sh` | OCI Bastion CI/CD 用の秘密鍵（`BASTION_OCI_PRIVATE_KEY`）をファイル入力で指定リポジトリへ登録する（AI 実行可。引数は `<owner/repo> <private_key_file>`、対話入力なし）。ユーザー OCID・フィンガープリントは秘密情報ではないため呼び出し側リポジトリのコードに直接定義する。GitHub の個人アカウントには Secrets の org 横断共有機能がないため、複数リポジトリで同一の CI/CD 専用 IAM ユーザーを使い回す際の登録の手間を共通化する |

- hook は `~/.claude/settings.json` の `PostToolUse`（`Write` / `Edit`）・`PreToolUse`（`Bash`）から
  `bash $HOME/.claude/scripts/{スクリプト名}` で呼び出す
- hook スクリプトは、Claude Code が標準入力で渡す JSON の `tool_input.file_path` を読む

## 5. 常駐プロセス（開発サーバ等）の起動と後始末

動作確認のために開発サーバ（`runserver`、`npm run dev` 等）やテスト用コンテナを起動する場合、
AI が起動したプロセスを残さない。`kill` / `pkill` に頼らず、起動方法で後始末を担保する。

- **開発サーバ**: Bash ツールの `run_in_background: true` で起動し、確認が終わったら
  `TaskStop` で止める。`( ... &)`・`nohup`・`disown` などで切り離して起動しない
  （切り離すと `TaskStop` で止められず、プロセスが残る）
- **寿命を付ける場合**: `timeout 600 {起動コマンド}` のように上限時間を付けて起動する
- **テスト用コンテナ**: `docker run --rm --name {名前}` で起動し、確認後に `docker stop {名前}` で止める
- 作業の完了報告の前に、起動したプロセス・コンテナがすべて停止していることを確認する。
  止められないものが残った場合は、ユーザーに停止コマンドを案内する
- `kill` / `pkill` が必要になった場合は、パターンに自身のコマンドラインが一致して
  実行中のシェルごと終了しないよう、`pkill -f "runserve[r]"` のように角括弧で一文字を囲む
