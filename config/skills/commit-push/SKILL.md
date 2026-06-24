---
name: commit-push
description: 現在の差分をコミットしてプッシュする個人用スキル。PR作成は行わない。コミット・プッシュまでを一貫して行う。「コミットしてプッシュ」「commit-pushで」などのリクエストで使用する。
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*)
---

# コミット & プッシュ（tokizuoh版）

現在の変更内容をコミットしてプッシュする。PR作成は行わない。

## ワークフロー

### 1. 変更内容の確認

以下を並列で実行して現在の状態を把握する。

```bash
git status
git diff HEAD
git log --oneline -10
```

変更がない場合はユーザーに報告して終了する。

### 2. ブランチ確認

現在のブランチを確認する。

```bash
git branch --show-current
```

確認後、**現在のブランチ（main・featureを問わず）に対して一旦中断し、「このままこのブランチにコミットするか / 新規ブランチを切るか」をユーザーに確認**してから進む。新規ブランチを切る場合はブランチ名を差分内容に応じてつける。

### 3. コミット

ステージングは `git add -A` ではなく変更対象のファイルを個別に指定する（機密ファイルや意図しないファイルを含めないため）。

コミットメッセージは以下のルールに従う。

- prefix を付ける（`feat: ` / `fix: ` / `refactor: ` / `rename: ` / `remove: ` など）
- prefix 以外は日本語で書く
- **co-author は含めない**（`Co-Authored-By` を付けない）

### 4. プッシュ

```bash
git push -u origin <branch-name>
```

プッシュ完了後、ブランチ名とコミット内容をユーザーに報告して終了する。
