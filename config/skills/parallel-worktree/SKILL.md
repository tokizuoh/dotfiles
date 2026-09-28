---
name: parallel-worktree
description: 作業を独立したタスクに分け、タスクごとに gwq で git worktree を作ってサブエージェントに並列で実装させ、各ブランチを push して Draft PR まで作る個人用スキル。今いるブランチを汚さずに実装させたいときや、複数の変更を並列で進めたいときに使う。タスクが1つでもよい。「worktree で並列に実装して」「今のブランチを汚さずにやって」「parallel-worktreeで」などのリクエストで使用する。
allowed-tools: Bash(gwt add:*), Bash(gwt list:*), Bash(git worktree list:*), Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git log:*), Bash(git diff:*), Bash(git fetch:*), Bash(git push:*), Bash(gh repo view:*), Bash(gh pr view:*), Bash(gh pr create:*), Bash(find:*)
---

# worktree で並列実装

作業をタスクに分け、タスクごとに worktree を作ってサブエージェントに実装・コミットさせる。push と Draft PR 作成はメインのセッションでまとめて行う。

## この進め方にした理由

- worktree は `gwt`（gwq を `gwt` にリネームしたもの。`mise/config.toml`）で作る
  - `~/worktrees/<host>/<owner>/<repo>/<branch>` に揃うので、`gwtcd` や cleanup-worktrees スキルでそのまま扱える
- `gwt add -b <branch>` は**今の HEAD から**ブランチを切る。基点を指定する引数はなく、第2引数は作成先のパスとして扱われる
  - 今の HEAD 以外を基点にするときは、先に `git branch <branch> <base>` でブランチを作ってから `gwt add <branch>` する
- 今いる worktree の未コミットの変更は新しい worktree に持ち込まれない
- push と PR 作成はサブエージェントにやらせない
  - create-pr / commit-push はユーザーへの確認（ブランチ・タイトル）を挟むが、サブエージェントはユーザーに確認できないため
  - タイトル確認を1回にまとめられるため

## ワークフロー

### 1. 状態の確認

以下を並列で実行する。

```bash
git branch --show-current
git status --porcelain
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
git worktree list
```

未コミットの変更がある場合は、それが新しい worktree に含まれないことをユーザーに伝える。その変更を前提にした実装を頼まれているなら、先にコミットするか確認する。

### 2. タスクの分割と計画の確認

依頼内容を、互いに独立して実装できるタスクに分ける。

- 同じファイルを複数のタスクが触りそうなら、1つのタスクにまとめるか、コンフリクトする可能性があることを計画に書く
- 別のタスクの成果を前提にするタスクは並列にできない。順番に実行するか、1つにまとめる

以下の表をユーザーに見せて承認を取る。ここでの確認が最後のまとまった確認になるので、曖昧な点はここで聞く。

| # | タスク | ブランチ名 | 基点 | PR の base |
|---|---|---|---|---|

- ブランチ名は prefix（`feat/` / `fix/` / `refactor/` など）を付け、内容が分かる名前にする。既存のブランチ・worktree と重ならないようにする
- 基点の既定は今のブランチの HEAD。デフォルトブランチから切りたいなどの希望があればそれに従う
- PR の base は基点のブランチにする

### 3. worktree の作成

タスクごとに作る。基点が今の HEAD の場合:

```bash
gwt add -b <branch>
```

基点が今の HEAD 以外の場合:

```bash
git fetch origin <base>
git branch <branch> origin/<base>
gwt add <branch>
```

作成後に `git worktree list --porcelain` を実行し、各ブランチの worktree の絶対パスを `worktree` 行から取る。パスは組み立てずにここで取った値を使う（サニタイズの規則が設定で変わるため）。

### 4. サブエージェントで並列実装

Agent ツールで、タスクごとに1つのサブエージェントを**1つのメッセージで同時に**起動する。`isolation` は指定しない（worktree は手順3で作ってあるため）。

プロンプトには以下を含める。サブエージェントは会話の文脈を持たないので、タスクの背景や決まったことは省略せずに書く。

- タスクの内容と完了条件
- 作業する worktree の絶対パスとブランチ名
- 守ること:
  - ファイルの読み書きは worktree の絶対パスで行う。Bash は毎回 `cd <worktree> && ...` で始めるか `git -C <worktree>` を使う（シェルのカレントディレクトリはメインの worktree に戻るため）
  - worktree の外（メインの worktree や他のタスクの worktree）は変更しない
  - 依存パッケージのインストールなど、worktree で動かすのに必要な準備は各自で行う
  - リポジトリにテストや lint があれば実行する
  - 変更はブランチにコミットする。ステージングは `git add -A` ではなくファイルを個別に指定する。コミットメッセージは prefix（`feat: ` など）を付け、prefix 以外は日本語で書く
  - push と PR 作成はしない
  - 判断に迷う点は推測で進めず、そこで止めて報告する
- 報告してほしいこと: コミット一覧、変更の要約、実行したテストとその結果、未解決の点

### 5. 結果の確認

全サブエージェントの完了を待ってから、worktree ごとに以下を確認する。

```bash
git -C <worktree> status --porcelain
git -C <worktree> log --oneline <base>..HEAD
git -C <worktree> diff <base>...HEAD --stat
```

- コミットがない、未コミットの変更が残っている、サブエージェントが未解決の点を報告した: そのタスクは PR を作らず、手順7で状況を報告する
- それ以外は手順6へ進める

### 6. push と Draft PR の作成

create-pr スキルの手順4〜8（差分の把握・テンプレート探索・本文作成・タイトル確認・作成）に従う。ただし以下を変える。

- コマンドは各 worktree で実行する（`git -C <worktree>` や `cd <worktree> && ...`）
- 本文の「動作確認」には、サブエージェントが実際に実行したテストの結果だけを書く。報告にないものは `- TODO` にする
- タイトル・本文・添付の確認は、全タスク分を一覧にして**一度にまとめて**ユーザーに見せる
- `--base` は手順2で決めた PR の base にする

確認が取れたら push して作成する。

```bash
git -C <worktree> push -u origin <branch>
cd <worktree> && gh pr create --draft --base <base> --title "<title>" --body-file <body-file> --assignee @me
```

### 7. 報告

以下を報告する。

- PR を作ったもの: ブランチ名、worktree のパス、PR の URL
- PR を作らなかったもの: ブランチ名、worktree のパス、理由
- worktree は残してあること。マージ後は cleanup-worktrees スキルで消せること
