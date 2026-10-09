---
name: gas-deploy
description: >
  Google Apps Script (clasp) の変更手順。
  GAS、スプレッドシート連携、Apps Script、通知トラッカーの修正時に使用。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# GAS Deploy

規約の詳細は [gas-deploy-flow.md](../../rules/gas-deploy-flow.md) に従う。
**スクリプト ID・デプロイメント ID・公開 URL など、リポジトリ固有の識別子は
プロジェクト個別の `CLAUDE.md` に従う**。

## 前提

- Clasp がインストール済みであること
- `.clasp.json` は `.gitignore` 済みのため、ローカルに設定が必要
- `.clasp.json` に固定の `deploymentId` が記録されていること

## 1. 設計書確認

関連する設計書を確認する（[docs-sync.md](../../rules/docs-sync.md) 1章）。
変更内容が設計書の方針・構成と乖離する、または設計書に記載のない新規要素を追加する場合は、
**先に設計書を更新してから**コード修正に着手する。
設計と実装が別 Issue の場合、または大規模な改修の場合のみ、設計書更新後にユーザーの承認を得てから
コード修正に進む（[docs-sync.md](../../rules/docs-sync.md) 1章）。

## 2. ファイル編集

対象の `.js` / `.ts` ファイルを編集する。

## 3. 差分確認

```bash
clasp status
```

意図しないファイルが含まれていないか確認する。特に `appsscript.json` が変更対象に入っている場合、
意図的な変更かどうかユーザーに確認する。

## 4. デプロイ

ウェブアプリとして公開する場合、`appsscript.json` にウェブアプリ設定
（`"webapp": {"executeAs": "USER_DEPLOYING", "access": "ANYONE_ANONYMOUS"}`）が
含まれていることを確認してから実行する。

```bash
clasp push
```

次に、**`.clasp.json` に記録された固定 deployment ID を使って既存デプロイを更新する**。

```bash
clasp deploy -i $(jq -r '.deploymentId' .clasp.json) -d "{変更内容}"
```

**重要**: 新しいデプロイメントを作成してはならない。URL が変わり、IaC 側の設定更新が必要になる。

## 5. 動作確認

- ユーザーに動作確認を促す。ウェブアプリの場合は URL を提示する
  （ブラウザキャッシュのクリア、またはシークレットモードでの確認を案内する）
- スプレッドシートへの書き込み確認・通知サブスクリプション確認など、
  すべての動作確認が完了するまで次に進まない

## 6. コミット

**ユーザーの動作確認が完了してから** `git add` → `git commit` → `git push` → PR 作成を行う。
動作確認前に `git push` や PR 作成を実施しないこと
（[git-workflow.md](../../rules/git-workflow.md) 12章のリリース方針。GAS は動作確認をユーザー自身が
行う対象のため、その完了を待つ。完了後のコミット・プッシュ・PR 作成に別途の許可は不要）。

**GAS + IaC の複合変更**の場合は、GAS デプロイ → 検証環境の `plan` / `apply` →
両方の動作確認完了、の順に実施してからコミットする。

## 7. 例外: CI/CD で自動デプロイするスクリプト

リポジトリに GitHub Actions のデプロイワークフローがある場合は、3〜6章に代えて
[gas-deploy-flow.md](../../rules/gas-deploy-flow.md) 5章に従う（ローカルから `clasp push` せず、
PR → CI → マージ承認 → CD の流れ。マージ後に CD の完了を監視して報告し、ユーザーが GAS エディタで
動作確認する）。
