---
paths:
  - "**/*.gs"
  - "**/appsscript.json"
  - "**/.clasp.json"
---

# GAS プロジェクトのデプロイフロー

Google Apps Script（GAS）のコード変更に関する共通規約。
スクリプト ID・デプロイメント ID・公開 URL などの固有の識別子は、
プロジェクト個別の `CLAUDE.md` に記載する。

## 1. 前提

- Clasp がインストール済みであること
- `.clasp.json` は `.gitignore` 済みのため、ローカルに設定が必要
- ウェブアプリとして公開する場合、`appsscript.json` にウェブアプリ設定を含める

  ```json
  "webapp": { "executeAs": "USER_DEPLOYING", "access": "ANYONE_ANONYMOUS" }
  ```

## 2. デプロイ手順

1. コード修正（ローカル）
2. `clasp status` で差分を確認する

   意図しないファイルが含まれていないか確認する。特に `appsscript.json` が変更対象に
   入っている場合、意図的な変更かどうかユーザーに確認する

3. `clasp push` でコードをスクリプトエディタへ反映する
4. **既存デプロイを更新する**（新規デプロイメントを作成しない）

   ```bash
   clasp deploy -i {deployment_id} -d "{変更内容の説明}"
   ```

5. ユーザーが GAS のウェブアプリ URL で動作確認する
   （ブラウザキャッシュをクリアするか、シークレットモードで確認）
6. 確認が取れてから `git push` → PR 作成 → ユーザーの承認を得てマージ

`clasp push` だけでは `/exec` URL には反映されない。必ず `clasp deploy -i` で既存デプロイを更新する。

## 3. デプロイメント ID の固定化

ウェブアプリの webhook URL を固定し、IaC 側の設定との同期を不要にするため、
デプロイメント ID を固定して運用する。

- **`.clasp.json` に `deploymentId` を記録する**: 固定デプロイメント ID を明示的に記録する
- **常に既存デプロイメントを更新する**: `clasp deploy` は**必ず** `-i {固定ID}` を付けて実行する。
  新しいデプロイメントを作成してはならない（URL が変わるため）

  ```bash
  clasp deploy -i $(jq -r '.deploymentId' .clasp.json) -d "{変更内容}"
  ```

- **URL をコード化する**: IaC 側の変数（webhook URL 等）は固定値として定義する。
  デプロイ後も URL の更新・IaC の再実行は不要になる
- `clasp deploy -i` は、`appsscript.json` の webapp 設定を含めた状態で実行する

## 4. コミット・動作確認のタイミング

- **コミットは `clasp push` による GAS デプロイ完了後に行う**
- **ユーザーの動作確認前に `git push` や PR 作成を実施しない**
  （[git-workflow.md](git-workflow.md) 5.1・12章のリリース方針に従う）
- **動作確認必須**: スプレッドシートへの書き込み確認・通知サブスクリプション確認など、
  すべての動作確認が完了するまでコミットに進まない
- **GAS + IaC の複合変更**: GAS デプロイ → 検証環境の `plan` / `apply` → 両方の動作確認完了、
  の順に実施してからコミットする
- `appsscript.json` の変更は、意図的な場合のみコミットする

## 5. 例外: CI/CD で自動デプロイするスタンドアロンスクリプト

ウェブアプリではなく時間主導型トリガーで動くスタンドアロンスクリプトで、リポジトリに
GitHub Actions のデプロイワークフローが存在する場合は、2〜4章のローカルからの
`clasp push` / `clasp deploy` に代えて、以下の流れとする。

1. PR 作成で CI（構文チェック等）を実行する
2. ユーザーの許可を得て `main` にマージする
3. マージをトリガーに、ワークフローが `clasp push` で GAS へ反映する（CD）
4. AI は CD の完了を監視して結果を報告し、ユーザーが GAS エディタで動作確認する

- ローカルから `clasp push` で直接デプロイしない（[git-workflow.md](git-workflow.md) 12章の
  「本番へのデプロイは常にマージ後の CD」の原則に従う）
- clasp の認証情報（`.clasprc.json`）は GitHub Secrets で管理し、コード・ログに出力しない
- デプロイ先が本番のみのため、動作確認はマージ後に行う。問題があれば修正 PR で対応する
