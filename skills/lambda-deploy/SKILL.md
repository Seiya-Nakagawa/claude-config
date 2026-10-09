---
name: lambda-deploy
description: >
  Lambda アプリのビルド・デプロイ手順。検証環境はローカルから、本番はCI/CD経由で適用する。
  Lambda アプリケーションコードの編集、関数コードの更新時に使用。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Lambda Deploy

Lambda 関数リソースは IaC（`terraform/` 等）側で作成済みである前提で、アプリ側は
関数コードのビルドとデプロイを行う。規約の詳細は [lambda.md](../../rules/lambda.md) と
[python.md](../../rules/python.md) に従う。
**ビルド／デプロイスクリプトのパス・関数名・CI のワークフロー名など、リポジトリ固有の値は
プロジェクト個別の `CLAUDE.md` に従う**。

## 前提

- クラウドの認証が完了していること
- 対象の Lambda 関数が IaC 側で作成済みであること
- コマンドはリポジトリのルートディレクトリから実行する（`cd` を使わない）

## 1. 設計書確認

関連する設計書を確認する（[docs-sync.md](../../rules/docs-sync.md) 1章）。
変更内容が設計書の方針・構成と乖離する、または設計書に記載のない新規要素を追加する場合は、
**先に設計書を更新してから**コード修正に着手する。
設計と実装が別 Issue の場合、または大規模な改修の場合のみ、設計書更新後にユーザーの承認を得てから
コード修正に進む（[docs-sync.md](../../rules/docs-sync.md) 1章）。

## 2. ファイル編集

- 対象アプリの `src/` 配下を編集する
- 依存追加時は `requirements.txt` を更新する（バージョン固定）
- 新規トリガー・IAM 権限・環境変数が必要な場合は、IaC 側の対応が必要な旨をユーザーに伝える

## 3. テスト

```bash
python3 -m venv /tmp/venv
/tmp/venv/bin/pip install -r {アプリディレクトリ}/requirements.txt pytest --quiet
/tmp/venv/bin/python -m pytest {アプリディレクトリ}/tests/ -v
```

テストが通過することを確認する。

## 4. ビルド

リポジトリのビルドスクリプトでデプロイ用 zip を生成し、ビルド出力先に生成されたことを確認する。

## 5. 検証環境への適用

承認を得たら、検証環境の関数コードを更新する。
まずクラウド上の実際の関数名を確認する。

```bash
aws lambda list-functions --query 'Functions[*].FunctionName' --output text
```

関数名を確認したうえでデプロイスクリプトを実行する。想定と異なる関数名の場合は明示指定する。
デプロイ結果（更新された関数・バージョン）をユーザーに報告する。

## 6. Lambda CLI 動作確認

デプロイ直後に関数を同期実行し、実際のクラウド連携を確認する。
手順・結果の判定方法は [lambda.md](../../rules/lambda.md) 6章を参照。

確認結果をユーザーに報告する
（[git-workflow.md](../../rules/git-workflow.md) 12章）。動作確認が完了するまで、
CI の起動契機となるコミット・プッシュ・PR 作成をしない。完了後はユーザーの許可なく
コミット・プッシュして次のステップへ進む。

## 7. 本番環境への適用について

**本番環境**: PR マージ後に CI/CD が自動実行する。
**ローカルから本番への直接デプロイは絶対に実施しない**。

## 8. PR 作成 & CI 確認

`/feature-flow` の PR 作成手順に従う。

PR オープンを契機にテスト・ビルドの CI が実行される。
PR 作成後、AI が自動で CI の完了を監視する（ユーザーの「CI 完了」報告を待たない）。

```bash
gh run watch $(gh run list --workflow={デプロイ用ワークフロー} --limit=1 --json databaseId -q '.[0].databaseId')
gh run view {run_id} --json url -q '.url'
```

CI の実行 URL を**必ずテキストメッセージでユーザーに出力する**。
CI が通っていればユーザーに報告してマージ承認を求める。

## 9. マージ後のデプロイ確認

マージ後、本番デプロイの CI 結果を監視・確認し、実行 URL と結果をユーザーに報告する。
デプロイ完了後、必要に応じて本番の Lambda 関数を `aws lambda invoke` で確認する。
