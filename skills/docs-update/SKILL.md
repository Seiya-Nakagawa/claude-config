---
name: docs-update
description: >
  ドキュメントのみの修正手順。
  README、設計ドキュメント、手順書など .md ファイルの更新時に使用。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Docs Update

規約の詳細は [document-standards.md](../../rules/document-standards.md)（体系・章立て・記述ルール）、
[docs-sync.md](../../rules/docs-sync.md)（同期フロー）、
[markdown.md](../../rules/markdown.md)（記法）に従う。

## 実施手順

### 1. ファイル編集

- 対象の `.md` ファイルを編集する
- 既存ドキュメントのフォーマット・見出し構造に合わせる
- 格納場所・ファイル名は [document-standards.md](../../rules/document-standards.md) 1章に従う

### 2. テキストチェック

markdownlint に準拠する。PostToolUse hook により `Write` / `Edit` 後に `markdownlint --fix` が
自動実行される環境では手動実行は不要。残存エラーがある場合は手動で修正する。

### 3. リンク確認

ドキュメント内のリンク（URL、相対パス）が有効か確認する。リンク切れを残さない。

### 4. コミット

- コミットメッセージは `docs: {概要}` 形式
- コード変更を含まないため、ビルド・デプロイ系の CI はスキップされる。
  デプロイ対象がないため、動作確認の手順（[git-workflow.md](../../rules/git-workflow.md) 12章）は省略し、
  動作確認を待たずに PR を作成してよい
- PR には `docs` 相当のラベルを付与する（[git-workflow.md](../../rules/git-workflow.md) 5章の標準ラベル）

## 設計書を更新する場合の追加ルール

- **インフラ管理プロジェクト（IaC で基盤を管理するリポジトリ）の基本設計書は、
  `docs/02.design/{NN}.{英名}/{章番号}章_基本設計書_{章タイトル}.md` の章立て分割を必須とする**。
  `DESIGN.md` は作成しない。章は
  [document-standards.md](../../rules/document-standards.md) 1.3.1節の標準章カタログから採用する
- アプリケーションプロジェクトの基本設計書は `docs/02.design/DESIGN.md` 1ファイルとする
- 記載するのは**確定事項のみ**とし、検討状況・対応経過・経緯は書かない
- 具体的なパラメータの網羅的な管理はコード側に任せ、方針レベルの記述に留める
- 実装のファイルパス・行番号・リソース名を本文に引用しない
- 他章・他ドキュメントへの参照は必ず Markdown の相対リンクにする
- ER 図・フローチャート・シーケンス図等は Mermaid を基本とする。システム構成図は
  drawio 形式とし、`02.design/99.appendix/別紙_{タイトル}.drawio.svg`（編集可能 SVG）として
  管理し、インフラ変更時に合わせて更新する
- 詳細は [document-standards.md](../../rules/document-standards.md) 5章・6章を参照
