#!/usr/bin/env python3
# 巨大なログを貼ると自動 compact が連発して文脈が落ちるため、Claude に届く前に止める。
# UserPromptSubmit は exit 2 でプロンプトを破棄し、stderr をユーザーに表示する。
import json
import sys

LIMIT_BYTES = 100_000

prompt = json.load(sys.stdin).get("prompt", "")
size = len(prompt.encode())
if size > LIMIT_BYTES:
    print(
        f"プロンプトが {size // 1000}KB あります（上限 {LIMIT_BYTES // 1000}KB）。"
        "ログなどはファイルに保存して、パスを渡してください。",
        file=sys.stderr,
    )
    sys.exit(2)
