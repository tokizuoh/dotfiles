#!/bin/bash
# 標準入力からJSON形式のデータを読み込む
input=$(cat)

# 各種情報を取得
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
duration_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // "0"')

# レイテンシを秒に変換（小数点1桁）
latency=$(echo "scale=1; $duration_ms / 1000" | bc)

# ccusage 未インストール時（brew bundle 前など）や失敗時に表示が消えないよう従来表示へフォールバックする
if command -v ccusage > /dev/null 2>&1 && usage=$(echo "$input" | ccusage statusline 2> /dev/null) && [ -n "$usage" ]; then
  # ccusage statusline は Beta で出力形式が変わりうるため、想定の4項目でなければ分割せずそのまま出す
  # 各項目先頭の絵文字を除去する。ccusage に絵文字を消すオプションが無いため。LC_ALL=C はマルチバイトをバイト単位で正規表現に掛けるため
  echo "$usage" | LC_ALL=C awk -F ' [|] ' -v OFS=' | ' -v latency="${latency}s" '
    { for (i = 1; i <= NF; i++) sub(/^[^ -~]+ /, "", $i) }
    NF == 4 { sub(" / [^/]* block.*$", "", $2); gsub(" / ", " | ", $2); print $1 " | " $4 " | " latency; print $2; next }
    { print $0 " | " latency }
  '
else
  echo "${model} | Context: ${used}% used | ${latency}s"
fi
