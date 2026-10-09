# GitHub 運用リファレンス

[git-workflow.md](../../rules/git-workflow.md) の詳細手順のうち、必要なときだけ参照するもの。
章番号は git-workflow.md の章番号に合わせている。

## 8. Milestone によるフェーズ管理

**Milestone・Project は、大きな対応でタスク管理が必要になった場合のみ作成・設定する。**
小規模な修正、ドキュメント更新、調査起点の単発対応など、単発タスクの Issue には設定しない
（AI が Milestone・Project を作成する場合も、事前にユーザーの了承を得る）。

大きな対応で Issue の一覧だけではプロジェクト全体の進捗・フェーズが把握しにくい場合に、
GitHub Milestone でフェーズ単位にグルーピングし、全体像を可視化する。
以下は、フェーズ管理を行う場合の規則である。

- 標準フェーズは [document-standards.md](../../rules/document-standards.md) の文書フェーズに
  構築・運用を加えた以下の単位とする。プロジェクトの性質に応じて増減してよい
  （例: ライブラリ開発では「デプロイ・移行」が不要な場合がある）
  1. 要件定義
  2. 基本設計
  3. 構築（詳細設計書・構築手順書を独立文書として作成する場合はそれもここに含める）
  4. デプロイ・移行
- **Milestone タイトルには `NN.フェーズ名` の形式で番号を付与する**
  （例: `01.要件定義`、`02.基本設計`、`03.構築`、`04.デプロイ・移行`）。
  GitHub Project で Milestone ごとにグループ化した際、フェーズ順に並ぶようにするための対応であり、
  グループの並び順を GitHub 側の機能で直接指定する手段がないための代替策である
- プロジェクト開始時、既に完了しているフェーズがあれば**遡って Milestone を作成**し、
  該当する Issue・PR を紐づけたうえで close する。進捗の全体像から欠落させない
- フェーズが完了したら、そのフェーズの Milestone を close する
- フェーズ管理を行っているプロジェクトでは、Issue 作成時に該当するフェーズの Milestone を設定する。
  単発タスクの Issue には設定しない

  ```bash
  gh issue create --title "{内容}" --body "{概要}" --milestone "{NN.フェーズ名}"
  ```

## 10. GitHub Project（プロジェクトボード）の運用

リポジトリに対応する GitHub Project（Projects v2）ボードが存在する場合、以下に従う。
Project の新規作成・削除は対象外とし、既存の Project の完了管理のみを扱う。
Project は、8章と同様に大きな対応でタスク管理が必要な場合のみ作成する（単発タスクでは不要）。

- Issue をクローズした（PR マージにより自動クローズされた場合を含む）タイミングで、
  そのリポジトリに対応する Project が存在するか確認する

  ```bash
  gh project list --owner {オーナー}
  ```

- 対応する Project が見つかった場合、紐づく全アイテムの状態を確認する

  ```bash
  gh project item-list {番号} --owner {オーナー} --format json
  ```

- **紐づく全アイテムが完了（Status が「Done」、または対応する Issue/PR がクローズ済み）に
  なった場合、AI はユーザーの確認を待たずに Project を自動でクローズしてよい**
  （git-workflow.md 1章の「AI が自動で実施する」対象に含む。Project のクローズは可逆操作であり、
  再オープンは `gh project close {番号} --owner {オーナー} --undo` で行える）

  ```bash
  gh project close {番号} --owner {オーナー}
  ```

- クローズした場合は、対象 Project 名と URL をユーザーへ報告する
- 未完了のアイテムが1件でも残っている場合はクローズしない

## 11. GitHub CLI（`gh`）利用時の注意点

`gh` CLI 利用時は以下に従う。

### 11.1. Issue の読み込み

`gh issue view` は `--json` で必要なフィールドを明示的に指定し、出力を限定する。

```bash
gh issue view {番号} --json title,body,labels,assignees,milestone,comments
```

### 11.2. 既存 Issue のタイトル・本文の更新

既存 Issue を参照して作業する場合、タイトルと本文が規約フォーマットに沿っていなければ更新する。
タイトルは `{Type}: {概要}`（git-workflow.md 4章の Conventional Commits に準拠）、本文は `## 概要` と
`## 対応内容`（チェックリスト）を含む形式とする。

```bash
gh issue edit {番号} \
  --title "{Type}: {概要}" \
  --body "$(cat <<'EOF'
## 概要
{Issue の目的・背景}

## 対応内容
- [ ] {具体的なタスク}
EOF
)"
```

### 11.3. PR の作成

`gh pr create` は**必ずヒアドキュメント展開形式**を使う。
`PR_BODY=$(mktemp)` + `--body-file` の複合コマンド形式は使わない。

```bash
gh pr create \
  --title "{Type}: {概要}" \
  --label {ラベル} \
  --body "$(cat <<'EOF'
## 概要
{内容}

## 変更内容
{内容}

## 確認事項
{内容}

Closes #{Issue番号}
EOF
)"
```

**理由**: `PR_BODY=$(mktemp) && ...` で始まる複合コマンドは `Bash(gh *)` の許可パターンに
マッチせず確認プロンプトが発生する。また `rm -f` が deny リストに入っている環境では
一時ファイルの後片付けも失敗する。
