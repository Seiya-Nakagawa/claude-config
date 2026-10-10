---
name: feature-flow
description: >
  Issue作成→ブランチ→作業→PR→マージの共通フロー。
  Terraform、GAS、Lambda、ドキュメント修正など種類を問わず使う。
  「Issue作って」「この変更をPRにして」「ブランチ切って作業して」等の指示で起動。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Feature Flow（共通フロー）

Issue 起票からマージまでの一連の流れを実行する。
規約の詳細は [git-workflow.md](../../rules/git-workflow.md) に従う。
Milestone・Project・`gh` の詳細手順は [GitHub 運用リファレンス](github-reference.md)、
CI 監視・マージ・対象別のリリース手順は [リリースフロー](release-flow.md) を参照する。
PR ラベルは git-workflow.md 5章の標準ラベルを使う。
CI のワークフロー名等の**リポジトリ固有の値は、
プロジェクト個別の `CLAUDE.md` に従う**。

## 1. タスク種別の判定

ユーザーの指示内容から以下を判定する。

- **terraform**: `.tf` ファイルの変更、インフラ変更 → `/tf-deploy` を併用
- **gas**: GAS（Apps Script）、スプレッドシート連携の変更 → `/gas-deploy` を併用
- **lambda**: Lambda アプリケーションコードの変更 → `/lambda-deploy` を併用
- **docs**: `.md` ファイルのみ、ドキュメント修正 → `/docs-update` を併用

判定に迷う場合はユーザーに確認する。

## 2. 認証確認

```bash
gh auth status
```

エラーが出た場合はユーザーに再認証を依頼して待機する。
クラウド認証が必要な場合は、種別に応じた個別スキルの認証手順に従う。

## 3. Issue 作成 / 参照

既存 Issue が指定された場合は新規作成をスキップし、内容を取得する
（`gh issue view` は `--json` 必須。[GitHub 運用リファレンス](github-reference.md) 11.1 参照）。

```bash
gh issue view {番号} --json title,body,labels,assignees,milestone,comments
```

取得後、タイトルと本文が規約フォーマットに沿っていなければ更新する
（[GitHub 運用リファレンス](github-reference.md) 11.2 参照）。

**Issue の起票はユーザーの確認を待たずに行う**（可逆操作のため承認対象としない。
[git-workflow.md](../../rules/git-workflow.md) 1章参照）。作業中に見つけた別件の課題・
改善点も同様にその場で起票し、起票後に Issue 番号・タイトル・URL をユーザーへ報告する。
ラベルがリポジトリに存在しない場合は `gh label create` で作成してから付与する。

新規作成の場合、Milestone・Project は設定しない。大きな対応でタスク管理が必要な場合のみ、
該当するフェーズの Milestone を `--milestone "{NN.フェーズ名}"` で設定する
（移行型プロジェクトは `{案件名} NN.フェーズ名`。[GitHub 運用リファレンス](github-reference.md) 8章参照）。

```bash
gh issue create \
  --title "{Type}: {概要}" \
  --label "{ラベル}" \
  --body "$(cat <<'EOF'
## 概要
{ユーザーの指示内容を要約}

## 対応内容
- [ ] {具体的なタスク}
EOF
)"
```

Issue 番号を取得して以降のステップで使う。

## 4. ブランチ作成

```bash
git switch main
git pull origin main
git switch -c {prefix}/issue-{番号}-{概要}
```

## 5. 作業実施

コード修正に着手する前に、関連する設計書を確認する
（[docs-sync.md](../../rules/docs-sync.md) 1章「作業前の設計書確認」を参照）。
変更内容が設計書の方針・構成と乖離する、または設計書に記載のない新規要素を追加する場合は、
**先に設計書を更新する**（「設計書 → コード」の順序を厳守）。

設計書を更新した場合は、原則ユーザー確認を挟まず、同一の Issue・ブランチ・PR のまま
種別に応じた個別スキルの手順に従ってコード修正に進む。

次の場合のみ、設計書の変更のみをコミット（`docs:` プレフィックス）・プッシュし、PR を作成する
（PR が未作成の場合は新規作成、既存 PR がある場合は追加コミットのプッシュのみでよい）。
PR の URL をユーザーに提示して設計書内容のレビューを依頼し、
**ユーザーから明示的な承認を得てから**コード修正に着手する。

- 設計と実装を別 Issue で管理している場合
- 大規模な改修の場合（複数コンポーネントにまたがる、構成・方式の根本的な変更、
  データ移行や不可逆な操作を伴う等）

設計書の方針に対してユーザーから修正・停止の指示があった場合はそれに従う。

## 6. デプロイ・動作確認

[git-workflow.md](../../rules/git-workflow.md) 12章のリリース方針に従う
（手順の詳細は [リリースフロー](release-flow.md)）。
**CI の起動契機となるコード変更をコミット・プッシュする前に**、ローカルまたはステージング環境（プロジェクトごとに異なる。
リポジトリ固有の値はプロジェクト個別の `CLAUDE.md` に従う）へデプロイし、動作確認を行う。
デプロイ・確認の具体的な手順は、種別に応じた個別スキル（`/tf-deploy`・`/lambda-deploy`・
`/gas-deploy`）に従う。

動作確認の結果をユーザーに報告する。動作確認が完了してからコミット・プッシュ・PR 作成に進む
（ユーザーの許可は不要。ユーザー自身の確認が必要な対象は、確認完了を待つ）。

ドキュメントのみの変更などデプロイ対象がない場合は、この手順を省略する。

## 7. 差分確認

```bash
git diff main...HEAD
```

変更内容の全容をユーザーに提示する（承認待ちはしない）。

## 8. コミット & プッシュ

CI の起動契機となるコード変更は、手順6の動作確認が完了した後に実施する
（ドキュメントのみの変更など、デプロイ対象がない変更は動作確認を待たなくてよい）。

```bash
git add {変更ファイルを個別指定}
git commit -m "{Type}: {概要}"
git push -u origin {ブランチ名}
```

## 9. PR 作成

PR オープンを契機に、GitHub Actions で CI またはドライラン（Terraform の `plan` 等）が実行される
構成の場合がある。動作確認前のコード変更は PR にしない。

`gh pr create` はヒアドキュメント展開形式を使う
（[GitHub 運用リファレンス](github-reference.md) 11.3 参照）。

```bash
gh pr create \
  --title "{Type}: {概要}" \
  --label "{ラベル}" \
  --body "$(cat <<'EOF'
## 概要
{このPRで何を実現するか、なぜ変更したか}

## 変更内容
{main ブランチとの差分をファイル単位・機能単位で網羅的に記載}

## 確認事項
{レビュー時に確認してほしい点、AI が仮定を置いて進めた箇所}

Closes #{Issue番号}
EOF
)"
```

PR 作成後、コマンド出力から URL を取得し、**必ずテキストメッセージでユーザーに提示する**
（コマンド出力のみに埋もれさせない）。

例: `PR を作成しました: https://github.com/{オーナー}/{リポジトリ}/pull/123`

## 10. CI 確認 & マージ

PR 作成後、AI が自動で CI の完了を監視する（ユーザーの「CI 完了」報告を待たない）。

```bash
gh pr checks {PR番号} --watch
```

CI 完了後、Terraform・GAS・Lambda の変更を含む場合は各ルールファイルの「CI 確認」手順に従い、
内容を検証してユーザーに提示する。CI が存在しない場合も、変更概要を提示する。
その後、**マージ承認をユーザーに求め**（CI に問題がない場合に限る）、承認を得たら実行する。

```bash
gh pr merge {PR番号} --squash --delete-branch
```

CI で問題が検出された場合は、修正のうえ手順6（デプロイ・動作確認）からやり直す。

マージをトリガーに GitHub Actions で CD（本番への自動デプロイ）が走る構成の場合は、
各ルールファイルの「Apply 確認（マージ後）」手順に従い、AI が結果を監視・確認してユーザーに報告する。

## 11. 後片付け

Apply 確認が完了した後、ローカル・リモートの作業ブランチを整理する
（`--delete-branch` 付きでマージした場合は自動で完了している）。

その後、[GitHub 運用リファレンス](github-reference.md) 10章に従い、対応する GitHub Project の
全アイテムが完了していれば Project をクローズする。
