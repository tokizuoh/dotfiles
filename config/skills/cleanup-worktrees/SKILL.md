---
name: cleanup-worktrees
description: マージ済みの PR に対応する git worktree を削除する個人用スキル。マージ済みかどうかは PR の状態で判定し、未コミットの変更や PR に入っていないローカルコミットがある worktree は残す。ローカルブランチの削除はユーザーに確認してから行う。「マージ済みの worktree を消して」「worktree 掃除して」「cleanup-worktreesで」などのリクエストで使用する。
allowed-tools: Bash(git fetch:*), Bash(git worktree list:*), Bash(git worktree remove:*), Bash(git worktree prune:*), Bash(git status:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(gh pr list:*)
---

# マージ済み worktree の削除（tokizuoh版）

マージ済みの PR に対応する worktree を削除する。ローカルブランチは消さずに残し、消すかどうかは最後にユーザーに確認する。

## この判定方法にした理由

- マージ済みかどうかは `git merge-base --is-ancestor` では判定しない。PR の状態で判定する
  - squash マージされたブランチは、マージ済みでも ancestor にならない
  - コミットを積んでいない作りかけのブランチは、未マージでも ancestor になる
  - 両方とも実際に起きた（sunnies リポジトリで 2026-09-24 に確認）
- untracked ファイルがあると `git worktree remove` に `--force` が要る
  - 実際に残っていたのは Gradle が自動生成する `mobile/gradle/gradle-daemon-jvm.properties` だった
  - ただし消してよいファイルはリポジトリごとに違うので、ファイル名を決め打ちせずユーザーに確認する
- CLOSED の PR や PR がないブランチは作業途中の可能性があるので、自動では消さない

## ワークフロー

### 1. リモートの最新化

```bash
git fetch --prune
```

### 2. worktree の一覧

```bash
git worktree list --porcelain
```

- 1件目はメインの worktree なので対象から外す
- worktree のパスの形は決め打ちしない。`worktree` 行の値をそのまま使う
- 以下は PR を調べずに「残す」扱いにする
  - `branch` 行がなく `detached` 行がある: ブランチがないので PR を引けないため
  - `locked` 行がある: `git worktree remove` が失敗するため
  - `prunable` 行がある: ディレクトリが既にないため。手順 6 の `git worktree prune` で片付く

### 3. 各 worktree の状態を調べる

`<branch>` は `branch` 行の値から `refs/heads/` を除いたもの。worktree ごとに以下を実行する（worktree 間は並列でよい）。

```bash
gh pr list --head <branch> --state all --json number,state,headRefOid
git -C <path> status --porcelain
git -C <path> rev-parse HEAD
```

- PR が複数返ってきた場合は、`headRefOid` がローカルの HEAD と一致するものを採用する。一致するものがなければ一番新しいもの（`number` が最大）を採用する
- `status --porcelain` の行は、先頭が `??` なら untracked、それ以外は追跡中ファイルの変更として数える

結果を表にしてユーザーに見せる。

| ブランチ | パス | PR | 状態 | HEAD 一致 | 追跡中の変更 | untracked | 判定 |
|---|---|---|---|---|---|---|---|

### 4. 削除候補の選定

以下を**全て**満たすものだけを削除候補にする。

- PR の `state` が `MERGED`
- ローカルの HEAD が PR の `headRefOid` と同じ（違えば PR に入っていないローカルコミットがある）
- 追跡中のファイルに変更がない（untracked だけなら可）

それ以外は残す。残す理由は次のいずれかで記録しておく。

- CLOSED / OPEN / PR なし / 変更あり / ローカルコミットあり / detached / locked / prunable

削除候補がなければ、表と残した理由を報告して手順 6 へ進む。

### 5. worktree の削除

削除候補のうち untracked ファイルがあるものは、worktree ごとにファイル名をまとめて見せ、**一度だけ**ユーザーに確認を取る。

- 承認された: `--force` で削除する
- 拒否された: その worktree は残す（理由: untracked あり）

```bash
# untracked ファイルがあり、承認されたもの
git worktree remove --force <path>
# untracked ファイルがないもの
git worktree remove <path>
```

untracked ファイルがないものに `--force` は付けない。想定外の変更を巻き込んで消さないため。

### 6. 後始末と報告

```bash
git worktree prune
```

以下の3つを報告する。

- 消したもの: ブランチ名と PR 番号
- 残したもの: ブランチ名と残した理由
- ローカルブランチは残っていること

### 7. ローカルブランチの削除（確認してから）

消した worktree のローカルブランチを削除するかユーザーに確認し、承認されたものだけ削除する。

```bash
git branch -D <branch>
```

squash マージされたブランチは `git branch -d` だと未マージ扱いで弾かれるので `-D` を使う。手順 4 で PR が MERGED かつ HEAD 一致を確認済みなので、`-D` でも失う変更はない。
