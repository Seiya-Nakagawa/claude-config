---
name: tf-deploy
description: >
  Terraform変更の実施手順。検証環境でのplan/apply、本番はCI/CD経由で適用する。
  .tfファイルの編集、インフラ変更、クラウドリソース追加・変更時に使用。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Terraform Deploy

規約の詳細は [terraform.md](../../rules/terraform.md) に従う。
plan / apply は共通スクリプト（`~/.claude/scripts/tf_plan.sh`・`tf_apply.sh`。
[terraform.md](../../rules/terraform.md) 10章）を使う。
**認証スクリプト・CI のワークフロー名など、リポジトリ固有の値は
プロジェクト個別の `CLAUDE.md` に従う**。

## 前提

- クラウドの認証が完了していること
- コマンドはリポジトリのルートディレクトリから実行する（`cd` を使わない）

## 1. 設計書確認

関連する設計書を確認する（[docs-sync.md](../../rules/docs-sync.md) 1章）。
変更内容が設計書の方針・構成と乖離する、または設計書に記載のない新規要素を追加する場合は、
**先に設計書を更新してから**コード修正に着手する。
設計と実装が別 Issue の場合、または大規模な改修の場合のみ、設計書更新後にユーザーの承認を得てから
コード修正に進む（[docs-sync.md](../../rules/docs-sync.md) 1章）。

## 2. ファイル編集

- 対象の `.tf` ファイルを編集する
- **リソース自体のサービス単位**でファイルを選ぶ（[terraform.md](../../rules/terraform.md) 5章）
- IAM リソースは `iam-*.tf` の命名規則に従って適切なファイルに追加する
- 変数追加時は `variables.tf` と環境ごとの `*.tfvars` の両方を更新する

## 3. 検証環境での検証（Plan）

`~/.claude/scripts/tf_plan.sh`（`fmt` / `init` / `validate` / `plan` を一括実行する）を実行する。
環境ごとに追加の引数が必要な場合は `TF_INIT_ARGS` / `TF_PLAN_ARGS` 環境変数で渡す。

実行結果から以下をユーザーに提示する（承認は待たず、次のステップに進む）。

- `Plan: X to add, Y to change, Z to destroy` の件数サマリー
- 追加・変更・削除されるリソースの一覧と詳細な変更点
- `destroy` や置換（`-/+`）を含む場合は、対象リソースを明示する

フルの plan 出力はログファイルに保存し、詳細確認が必要な場合のみ Read ツールで読む（トークン節約）。

**今回のコード変更で意図した差分以外（ドリフト）が含まれていないか確認する**
（[terraform.md](../../rules/terraform.md) 3.1章）。ドリフトがある場合は手順4に進まず、
ドリフトの内容をユーザーに報告し、対応方針の指示を待つ。

## 4. 検証環境への適用（Apply）

ドリフトがなければ、ユーザーの承認を待たず、`~/.claude/scripts/tf_apply.sh` で保存された
実行計画を適用する。適用が完了し、手順3の plan の差分どおりに変更が行われたことを確認してから
次に進む。

## 5. 動作確認・コミット & プッシュ

適用先の環境で動作確認を行い、結果をユーザーに報告する
（[git-workflow.md](../../rules/git-workflow.md) 12章）。動作確認が完了するまで、
CI の起動契機となるコミット・プッシュ・PR 作成をしない。完了後はユーザーの許可なく実施してよい。

```bash
git add {変更ファイルを個別指定}
git commit -m "{Type}: {概要}"
git push origin {ブランチ名}
```

## 6. 本番環境への適用について

**本番環境**: PR マージ後に CI/CD が自動実行する。
**ローカルから本番の plan・apply は絶対に実施しない**。

## 7. PR 作成 & CI 確認

`/feature-flow` の PR 作成手順に従う。

PR オープンを契機に CI（`plan` のドライラン）が実行される構成の場合、
PR 作成後、AI が自動で CI の完了を監視する（ユーザーの「CI 完了」報告を待たない）。

```bash
gh run watch $(gh run list --workflow={PR用ワークフロー} --limit=1 --json databaseId -q '.[0].databaseId')
```

CI の実行 URL を取得し、**必ずテキストメッセージでユーザーに出力する**。

```bash
gh run view {run_id} --json url -q '.url'
```

CI 完了後、plan 出力を取得して手順3で提示した内容と比較する。

```bash
gh run view --log {run_id}
```

**属性（パラメータ）単位で差分を確認する**: `Plan: X to add, Y to change, Z to destroy` の件数や
リソース名の一致だけで済ませず、各リソースの diff に含まれる `+`/`-`/`~` 行を1行ずつ照合し、
今回のコード変更で意図した属性のみが変化しているかを検証する。コード変更前から本番実態と
コードがズレていたドリフト等、意図していない属性変更が含まれる場合は見落とさずユーザーに報告する。

差分がなければユーザーに結果を報告してマージ承認を求める。
**削除（destroy）を含む PR を承認待ちのまま開いたままにしない**
（[terraform.md](../../rules/terraform.md) 9章）。

## 8. マージ後の apply 確認

PR マージ後、AI が自動で本番 apply の完了を監視する。

```bash
gh run watch $(gh run list --workflow={マージ用ワークフロー} --limit=1 --json databaseId -q '.[0].databaseId')
gh run view {run_id} --json url -q '.url'
```

apply の実行 URL を**必ずテキストメッセージでユーザーに出力する**。
apply 完了後、ログを取得して検証環境と同件数であることを確認し、ユーザーに報告する。

## 9. 後片付け

Issue のクローズを確認後、`/feature-flow` の後片付け手順に従う。
