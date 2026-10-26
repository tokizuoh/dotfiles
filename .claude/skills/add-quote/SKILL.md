---
name: add-quote
description: sebone mod がプロンプト上に出す名言ファイル（claude/quotes.json）に名言を1件足し、develop にコミットする dotfiles リポジトリ専用スキル。「名言追加して」「この一文を背骨に入れて」「add-quote で」などのリクエストで使用する。
allowed-tools: Bash(jq:*), Bash(mv:*), Bash(realpath:*)
---

# 名言の追加

`claude/quotes.json` に名言を1件足す。

## 書き込み先

mod は `~/.claude/skills/sebone` のリンク先（実体の `claude/mods/sebone`）から2つ上の `claude/quotes.json` を読む（`claude/mods/sebone/hooks/register.tsx` の `quotesPath`）。worktree の中から呼ばれても、必ずこちらに書き込む。worktree 側のファイルを直しても表示は変わらない。

ホームや ghq の置き場所は PC ごとに違うので、パスは毎回リンクから求める。

```bash
realpath ~/.claude/skills/sebone
```

出力から末尾の `/claude/mods/sebone` を除いたものを `REPO`、`$REPO/claude/quotes.json` を `Q` とする。以下のコマンドでは、`$REPO` と `$Q` を解決した絶対パスに置き換えて実行する。リンクが無い・解決できないときは、bootstrap.sh が未実行の可能性があるので何もせずユーザーに報告して止まる。

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
