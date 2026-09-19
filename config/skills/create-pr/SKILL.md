---
name: create-pr
description: 現在のブランチから GitHub の Draft PR を作成する個人用スキル。リポジトリに PR テンプレートがあればそれに従い、なければ既定フォーマット（概要/変更/動作確認/関連）で本文を書く。未 push のコミットがあれば push してから作成する。「PR作って」「プルリク出して」「create-prで」「PRにして」などのリクエストで使用する。
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git push:*), Bash(gh repo view:*), Bash(gh pr view:*), Bash(gh pr create:*), Bash(find:*), Bash(ls:*), Bash(cat:*)
---

# Draft PR 作成（tokizuoh版）

現在のブランチから GitHub の Draft PR を作成する。

## ワークフロー

### 1. 状態の確認

以下を並列で実行する。

```bash
git status
git branch --show-current
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
gh pr view --json url 2>/dev/null
```

以下の場合は中断してユーザーに報告する。

- 未コミットの変更がある: PR に含めるべきか判断できないため。commit-push スキルの利用を提案する
- 現在のブランチがデフォルトブランチ: PR の head にできないため
- 既にこのブランチの PR が存在する: URL を伝える

### 2. push

upstream が無い、またはリモートより進んでいる場合は push する。

```bash
git push -u origin <branch-name>
```

### 3. 差分の把握

`<base>` はデフォルトブランチ。

```bash
git log --oneline <base>..HEAD
git diff <base>...HEAD --stat
git diff <base>...HEAD
```

本文はこのブランチの全コミットを対象に書く。最新コミットだけを見て書くと変更が漏れるため。

### 4. PR テンプレートの探索

GitHub が PR テンプレートとして認識する場所を探す（ファイル名は大文字小文字を区別しない）。

- `pull_request_template.md`（ルート / `.github/` / `docs/`）
- `PULL_REQUEST_TEMPLATE/` 配下の `.md`（ルート / `.github/` / `docs/`）

```bash
find . -maxdepth 3 -ipath '*pull_request_template*' -not -path '*/node_modules/*' -type f
```

- 1つ見つかった: その見出し構成・チェックリストに従って本文を書く。テンプレート内のコメント（`<!-- -->`）は記入ガイドとして読み、本文には残さない
- 複数見つかった: どれを使うかユーザーに確認する
- 見つからない: 下の既定フォーマットを使う

### 5. 本文の作成

#### 既定フォーマット

```markdown
## 概要

## 変更

## 動作確認

## 関連
```

#### 書き方（テンプレートの有無を問わず適用）

- 各項目は箇条書きで書く
- 一つの箇条書きの中で句点「。」が付く場合は、次の文を次の行に書く
- 冗長な記載をなくし、簡潔に書く。足りない分は後からユーザーが補足する前提なので、網羅より簡潔さを優先する
- 差分やコミットから読み取れない事実（動作確認の結果、関連 issue など）は推測で埋めない。分からない項目は `- TODO` と書いておき、ユーザーが補足できるようにする
  - ブランチ名やコミットメッセージに issue 番号があれば「関連」に書く

例（既定フォーマット）:

```markdown
## 概要
- ログイン画面にパスワード表示切替を追加する

## 変更
- `LoginView` に表示切替ボタンを追加
- パスワード欄の入力制御を `SecureField` と `TextField` の切替に変更
  `SecureField` 単体では表示切替ができないため

## 動作確認
- TODO

## 関連
- TODO
```

### 6. タイトルの確認

差分から PR タイトル案を作り、ユーザーに提示してタイトルを確認する。ユーザーごと・リポジトリごとに好みが違うため、案をそのまま使わず必ず確認を取る。
本文もあわせて提示し、修正があれば反映する。

### 7. Draft PR の作成

本文はファイル経由で渡す（改行やバッククォートがシェルで崩れないようにするため）。一時ファイルはスクラッチパッドがあればそこに置く。
assignee には必ず自分（`@me`）を付ける。

```bash
gh pr create --draft --base <base> --title "<title>" --body-file <body-file> --assignee @me
```

作成後、PR の URL をユーザーに報告して終了する。
