---
paths:
  - "**/lambda/**"
  - "**/template.yaml"
  - "**/samconfig.toml"
---

# AWS Lambda 規約

全リポジトリ共通の Lambda 運用規約。
ビルド・デプロイスクリプトのパス、AWS アカウント ID、関数名、CI のワークフロー名など、
**リポジトリ固有の値はプロジェクト個別の `CLAUDE.md` に従う**。
アプリケーションコードの実装規約は [python.md](python.md) を参照する。

## 1. 責務分担（IaC との境界）

- **IaC（`terraform/` 等）**: Lambda 関数リソース（`aws_lambda_function`）、実行用 IAM ロール、
  トリガー（API Gateway・EventBridge・SQS 等）、環境変数、エイリアス、VPC 設定など
  **インフラ定義**を管理する
- **アプリ（`lambda/` 等）**: 関数に載せる**アプリケーションコードとビルド成果物（zip）**を管理し、
  関数コードの更新（デプロイ）を行う
- 関数リソースの新規作成・トリガー追加・IAM 権限変更が必要な場合は、IaC 側の対応を先に
  （または並行して）行う

## 2. 実行担当の分担

- **AI**: ファイル編集、クラウド認証の実行、ビルド実行、検証環境へのデプロイ実行、結果の抽出・提示
- **ユーザー**: 認証情報（MFA コード等）の提供、デプロイ対象・タイミングの承認

## 3. 標準デプロイフロー

Lambda 関数リソースが IaC 側で作成済みであることを前提に、以下の順序で実施する。

1. AI: アプリケーションコードを編集する
2. AI: ユニットテストを実行して通過を確認する（`pytest`）
3. AI: デプロイ用 zip を生成する
4. AI: 検証環境へコードを反映する（`aws lambda update-function-code` 相当）
5. AI: デプロイ結果（更新された関数・バージョン）をユーザーに報告する
6. AI: `aws lambda invoke` で関数を同期実行し、レスポンスとログを確認する（6章参照）
7. AI: 動作確認結果をユーザーに報告する
8. AI: 動作確認の完了後にコミット・プッシュ・PR 作成を行う（[git-workflow.md](git-workflow.md) 12章。
   PR オープンを契機に CI でテスト・ビルドが実行される）

## 4. 環境ごとの適用方針

- **検証・ステージング環境**: ローカルからのデプロイスクリプト実行を許可する。
  IaC で作成済みの関数のコードのみを差し替える
- **本番環境**: PR を `main` にマージ後、CI/CD が自動でデプロイする。
  **ローカルから本番への直接デプロイは行わない**
- CI/CD のクラウド認証はロール ARN を Secrets 等から参照し、ARN をワークフローにハードコードしない

## 5. 命名・配置規約

- アプリディレクトリ名と Lambda 関数名は対応させる（IaC 側の関数名と齟齬が出ないようにする）
- ビルド成果物（zip）はビルド用ディレクトリに出力し、git 管理しない（`.gitignore` 対象とする）
- パッケージサイズが大きい場合は S3 経由のデプロイを検討する
  （その場合の S3 バケット・キーは IaC の定義に合わせる）

## 6. Lambda CLI 動作確認

デプロイ後、以下のコマンドで関数を同期実行してレスポンスとログを確認する。

```bash
aws lambda invoke \
  --function-name {関数名} \
  --payload '{}' \
  --log-type Tail \
  --query 'LogResult' \
  --output text \
  /tmp/lambda-response.json | base64 -d
cat /tmp/lambda-response.json
```

### 6.1. 結果の判定

| 状態 | 判定方法 |
| --- | --- |
| 正常終了 | レスポンスに `FunctionError` が含まれない かつ `error=0` |
| 一部エラー | `FunctionError` なし かつ レスポンスボディに `error=N`（N > 0）が含まれる |
| アプリ内例外 | `"FunctionError": "Handled"` が含まれる（アプリが例外を捕捉して返した） |
| 予期しないエラー | `"FunctionError": "Unhandled"` が含まれる |

**ポイント**: `FunctionError` がなくてもレスポンスボディの `error=N` を必ず確認すること。

### 6.2. よくあるエラーと対処

| エラーメッセージ | 原因 | 対処 |
| --- | --- | --- |
| 必須パラメータが SSM に存在しない | SSM パラメータ未登録 | IaC 側でパラメータを登録する |
| `AccessDeniedException` | IAM 権限不足 | IaC 側で IAM ロールに権限を追加する |
| `Task timed out` | タイムアウト | IaC 側でタイムアウト値を延長する |
| `invalid_grant` | リフレッシュトークンが無効または期限切れ | SSM 上のトークンを最新の値に更新する |

## 7. CI 確認・デプロイ確認

PR 作成後の CI 監視、マージ後のデプロイ監視と結果報告は
[git-workflow.md](git-workflow.md) 9章に従う。
デプロイ完了後、必要に応じて本番の関数を `aws lambda invoke` で確認し、ユーザーに報告する。
