---
name: markitdown
description: PDF・Office ファイル（Word/Excel/PowerPoint）・画像・Web ページの URL など、Claude が直接読みにくい資料を markitdown CLI で Markdown に変換し、内容を読めるようにする。ユーザーが PDF などのファイルパスや URL を渡して「読んで」「変換して」「要約して」「参考にして」と言ったとき、または Claude が直接読めない形式の資料を渡されたときに使用する。
allowed-tools: Bash(markitdown:*), Bash(mkdir:*), Bash(date:*), Read, Write
---

# markitdown で資料を Markdown に変換して読む（tokizuoh版）

PDF・Office ファイル・画像・Web ページなど、Claude が直接読みにくい資料を
[microsoft/markitdown](https://github.com/microsoft/markitdown) の CLI で Markdown に
変換し、変換結果を読んでユーザーの依頼に応える。

前提: `markitdown` は uv tool で常設インストール済み（`~/.local/bin/markitdown`、PATH 済み）。
未インストールなら dotfiles の `bootstrap.sh` が `uv tool install 'markitdown[all]'` を実行する。

## 入力の種類

markitdown CLI は以下を引数で直接受け取れる（実機確認済み）。

- ローカルファイル: PDF / Word(.docx) / Excel(.xlsx) / PowerPoint(.pptx) / 画像 など
- Web ページの URL: `markitdown "https://example.com"` のように URL をそのまま渡せる

## ワークフロー

### 1. 入力の確認

ユーザーが渡したものがローカルファイルのパスか URL かを判定する。
複数渡された場合はそれぞれ変換する。

### 2. 出力先の決定

変換結果は **プロジェクトルートの `.tokizuoh/` 配下** に保存する（CLAUDE.md のルールに準拠）。
ファイル名は日付始まりで、内容が分かる英数字 slug を付ける。

```bash
# 今日の日付を取得（例: 20260625）
date +%Y%m%d
# .tokizuoh が無ければ作る
mkdir -p .tokizuoh
```

ファイル名の例: `.tokizuoh/20260625-paper-title.md` / `.tokizuoh/20260625-example-com.md`

### 3. 変換

`-o` で出力先を指定して変換する。

```bash
# ローカルファイル
markitdown path/to/file.pdf -o .tokizuoh/20260625-xxx.md

# URL
markitdown "https://example.com/page" -o .tokizuoh/20260625-xxx.md
```

注意:
- 起動時に `Couldn't find ffmpeg or avconv` という警告が stderr に出ることがあるが、
  これは音声変換用で PDF / Office / URL 変換には影響しない。無視してよい。
- 変換に失敗した場合（暗号化 PDF・対応外形式・URL 取得失敗など）は、エラー内容を
  ユーザーに報告し、推測で内容を補わない。

### 4. 読んで応える

変換した `.md` を Read で読み、ユーザーの当初の依頼（要約・参照・質問への回答など）に応える。
大きいファイルは必要な箇所だけ部分的に読む。

### 5. 報告

変換した `.md` のパスをユーザーに伝える。成果物として `.tokizuoh/` に残るので、
後から再利用できる旨を添える。
