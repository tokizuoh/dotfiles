---
name: add-quote
description: sebone mod がプロンプト上に出す名言ファイル（claude/quotes.json）に名言を1件足し、develop にコミットする dotfiles リポジトリ専用スキル。「名言追加して」「この一文を背骨に入れて」「add-quote で」などのリクエストで使用する。
allowed-tools: Bash(jq:*), Bash(mv:*), Bash(git -C /Users/tokizo/ghq/github.com/tokizuoh/dotfiles status:*), Bash(git -C /Users/tokizo/ghq/github.com/tokizuoh/dotfiles branch:*), Bash(git -C /Users/tokizo/ghq/github.com/tokizuoh/dotfiles diff:*), Bash(git -C /Users/tokizo/ghq/github.com/tokizuoh/dotfiles add claude/quotes.json), Bash(git -C /Users/tokizo/ghq/github.com/tokizuoh/dotfiles commit:*)
---

# 名言の追加

`claude/quotes.json` に名言を1件足す。

## 書き込み先

mod は次の絶対パスを読む（`claude/mods/sebone/hooks/register.tsx` の `QUOTES_PATH`）。worktree の中から呼ばれても、必ずこちらに書き込む。worktree 側のファイルを直しても表示は変わらない。

```
/Users/tokizo/ghq/github.com/tokizuoh/dotfiles/claude/quotes.json
```

以下では `REPO=/Users/tokizo/ghq/github.com/tokizuoh/dotfiles`、`Q=$REPO/claude/quotes.json` とする。

## ワークフロー

### 1. 本文と出典を決める

- 本文（`text`）は必須。出典（`source`）は任意で、URL か書名・記事名を入れる。
- URL しか渡されなかったら、どの一文を入れるかユーザーに聞く。自分で抜き出して決めない。
- 本文は前後の空白を落とし、途中の改行は取り除いて1行にする。帯は1行で表示する前提のため。

### 2. 書き込み先の状態を確かめる

```bash
git -C $REPO branch --show-current
git -C $REPO status --short
```

ブランチが `develop` でないとき、または `claude/quotes.json` 以外に未コミットの変更があるときは、何もせずにユーザーへ報告して止まる。

### 3. 重複を確かめる

```bash
jq --arg t "<本文>" 'any(.[]; .text == $t)' $Q
```

`true` なら追加せず、すでにあることを伝えて終わる。mod は直前と違う名言を `text` の一致で選ぶので、重複は意味がない。

### 4. 追加する

出典がなければ `--arg s ""` を渡す。そうすると `source` キーは付かない。

```bash
jq --arg t "<本文>" --arg s "<出典>" \
  '. + [{text: $t} + (if $s == "" then {} else {source: $s} end)]' \
  $Q > $Q.tmp && mv $Q.tmp $Q
jq empty $Q
git -C $REPO diff -- claude/quotes.json
```

`jq empty` が失敗したら `git -C $REPO checkout -- claude/quotes.json` で元に戻す前にユーザーに確認する。

### 5. コミットする

```bash
git -C $REPO add claude/quotes.json
git -C $REPO commit -m "feat: 名言を追加する"
```

push するかはユーザーに確認してから行う。

### 6. 報告する

追加した名言と diff、コミットの有無を伝える。mod は送信のたびにファイルを読み直すので再読み込みはいらない。ただし、選び方がランダムなので、すぐ出るとは限らないことも添える。
