#!/bin/bash
# Tsuika - Quick idea capture tool (v1.1)

FILE=""

# === ファイル存在確認 ===
if [[ ! -f "$FILE" ]]; then
  echo "❌ $FILE が見つかりません。"
  echo "手動でファイルを作成してから、再度実行してください。"
  exit 1
fi

# === コマンドライン引数の処理 ===
case "$1" in
  --list)
    # メモ一覧を表示
    if [[ ! -s "$FILE" ]]; then
      echo "📝 メモはまだありません。"
      exit 0
    fi
    
    echo "📋 保存されているメモ一覧:"
    echo ""
    
    # メモエントリ全体を表示
    entry_num=1
    current_entry=""
    in_entry=false
    
    while IFS= read -r line; do
      if [[ "$line" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}\]$ ]]; then
        # 新しいエントリの開始
        if [[ $entry_num -gt 1 && -n "$current_entry" ]]; then
          echo "$current_entry"
          echo ""
        fi
        current_entry="[$entry_num] $line"
        in_entry=true
        ((entry_num++))
      elif [[ "$line" == "----------------------------------------" ]]; then
        # エントリの終了
        if [[ -n "$current_entry" ]]; then
          echo "$current_entry"
          echo ""
        fi
        current_entry=""
        in_entry=false
      elif [[ $in_entry == true ]]; then
        # エントリの内容を追加
        current_entry+=$'\n'"$line"
      fi
    done < "$FILE"
    
    # 最後のエントリを表示
    if [[ -n "$current_entry" ]]; then
      echo "$current_entry"
    fi
    echo ""
    exit 0
    ;;
    
  --search)
    # 検索機能
    if [[ -z "$2" ]]; then
      echo "❌ 検索キーワードを指定してください。"
      echo "使用例: $0 --search キーワード"
      exit 1
    fi
    
    keyword="$2"
    echo "🔍 「$keyword」で検索中..."
    echo ""
    
    found=false
    current_entry=""
    in_entry=false
    
    while IFS= read -r line; do
      if [[ "$line" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}\]$ ]]; then
        # 新しいエントリの開始
        if [[ "$current_entry" =~ $keyword ]]; then
          echo "$current_entry"
          echo ""
          found=true
        fi
        current_entry="$line"
        in_entry=true
      elif [[ "$line" == "----------------------------------------" ]]; then
        # エントリの終了
        if [[ "$current_entry" =~ $keyword ]]; then
          echo "$current_entry"
          echo ""
          found=true
        fi
        current_entry=""
        in_entry=false
      elif [[ $in_entry == true ]]; then
        # エントリの内容を追加
        current_entry+=$'\n'"$line"
      fi
    done < "$FILE"
    
    # 最後のエントリをチェック
    if [[ -n "$current_entry" && "$current_entry" =~ $keyword ]]; then
      echo "$current_entry"
      echo ""
      found=true
    fi
    
    if [[ $found == false ]]; then
      echo "（該当するメモが見つかりませんでした）"
    fi
    
    exit 0
    ;;
    
  --help|-h)
    # ヘルプ表示
    echo "Tsuika - Quick idea capture tool (v1.1)"
    echo ""
    echo "使用方法:"
    echo "  $0             メモを入力・保存"
    echo "  $0 --list      保存されているメモの一覧を表示"
    echo "  $0 --search <キーワード>  メモを検索"
    echo "  $0 --help      このヘルプを表示"
    echo ""
    exit 0
    ;;
    
  "")
    # 引数なし: 通常のメモ入力モード
    ;;
    
  *)
    echo "❌ 不明なオプション: $1"
    echo "使用例: $0 --help"
    exit 1
    ;;
esac

# === 通常のメモ入力モード ===
echo "💡 ひらめいたことをメモしてください（Enter 2回で終了）"
echo ""

memo_content=""
count=0
while true; do
  IFS= read -r line
  if [[ -z "$line" ]]; then
    ((count++))
    [[ $count -eq 2 ]] && break
  else
    if [[ -z "$memo_content" ]]; then
      memo_content="$line"
    else
      memo_content+=$'\n'"$line"
    fi
    count=0
  fi
done

if [[ -n "$memo_content" ]]; then
  timestamp=$(date "+[%Y-%m-%d %H:%M]")
  {
    echo "$timestamp"
    echo "$memo_content"
    echo "----------------------------------------"
  } >> "$FILE"
  echo "✅ 保存しました: $FILE"
else
  echo "（メモは空でした。保存されません）"
fi

