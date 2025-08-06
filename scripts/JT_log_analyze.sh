#!/bin/bash

BASE_DIR="/mnt/c/working/Higo_bank/Analyze_tool/file/ジョブ実行テスト実施ログ/STEP1"
LOG_DIR="$BASE_DIR/log"
LIST_FILE="$BASE_DIR/analyze_list/analyze_list.csv"
OUT_OK="$BASE_DIR/check_result/log_judge_ok.csv"
OUT_NG="$BASE_DIR/check_result/log_judge_ng.csv"
OUT_UNKNOWN="$BASE_DIR/check_result/log_judge_unknown.csv"
OUT_NOTFOUND="$BASE_DIR/check_result/list_not_found_log.csv"

mkdir -p "$BASE_DIR/check_result"
# BOM付きヘッダ
echo -e '\xEF\xBB\xBFファイル名,行数,判定理由,エビデンス' > "$OUT_OK"
echo -e '\xEF\xBB\xBFファイル名,行数,判定理由,エビデンス' > "$OUT_NG"
echo -e '\xEF\xBB\xBFファイル名,行数,判定理由,エビデンス' > "$OUT_UNKNOWN"
echo -e '\xEF\xBB\xBFリスト名,備考' > "$OUT_NOTFOUND"

DATE_PATTERN='^[0-9]{4}年[[:space:]]+[0-9]{1,2}月[[:space:]]+[0-9]{1,2}日 [^ ]+ [0-9]{2}:[0-9]{2}:[0-9]{2} JST$'

# 1行目（ヘッダ）をスキップして2行目以降のみ処理
tail -n +2 "$LIST_FILE" | while read -r PROC; do
  # 空行スキップ、CR除去、前後空白除去
  PROC=$(echo "$PROC" | tr -d '\r' | xargs)
  [ -z "$PROC" ] && continue

  LOGS=( "$LOG_DIR/${PROC}"*.log )
  if [ ! -e "${LOGS[0]}" ]; then
    echo "$PROC,ログファイルが見つかりません" >> "$OUT_NOTFOUND"
    continue
  fi

  for LOG in "${LOGS[@]}"; do
    LOG_NAME=$(basename "$LOG")
    REASON=""
    EVIDENCE=""
    FILE_OK=0
    FILE_NG=0
    LINE_COUNT=$(wc -l < "$LOG")
    mapfile -t lines < "$LOG"
    total=${#lines[@]}
    last_idx=$((total-1))
    if [[ "${lines[$last_idx]}" =~ ^[[:space:]]*$ ]]; then
      last_idx=$((last_idx-1))
    fi
    # 「に失敗しました！」がある場合は無条件でNG
    if grep -q "に失敗しました！" "$LOG"; then
      REASON="失敗メッセージ検出"
      EVIDENCE=$(grep -n "に失敗しました！" "$LOG" | head -1)
      FILE_NG=1
    fi
    # 「SQLCMD実行中にエラーが発生しました。」がある場合は無条件でNG
    if grep -q "SQLCMD実行中にエラーが発生しました。" "$LOG"; then
      REASON="失敗メッセージ検出"
      EVIDENCE=$(grep -n "SQLCMD実行中にエラーが発生しました。" "$LOG" | head -1)
      FILE_NG=1
    fi
    # FILE_NG=0 かつ 最終行が日付形式
    if [ "$FILE_NG" -eq 0 ] && [[ "${lines[$last_idx]}" =~ $DATE_PATTERN ]]; then
      prev1_idx=$((last_idx-1))
      prev1="${lines[$prev1_idx]}"
      prev3_idx=$((last_idx-3))
      prev3="${lines[$prev3_idx]}"
      if [[ "$prev1" =~ に成功しました！ ]]; then
        REASON="成功メッセージ検出"
        EVIDENCE="$((prev1_idx+1))行目:${prev1},$((last_idx+1))行目:${lines[$last_idx]}"
        FILE_OK=1
      elif [[ "$prev1" =~ ^[[:space:]]*\(1\ rows\ affected\)[[:space:]]*$ ]]; then
        if [[ "$prev3" =~ ^[[:space:]]*0[[:space:]]*$ ]]; then
          REASON="最終日付直前パターン（0→(1 rows affected)→日付）"
          EVIDENCE="$((prev3_idx+1))行目:${prev3},$((prev1_idx+1))行目:${prev1},$((last_idx+1))行目:${lines[$last_idx]}"
          FILE_OK=1
        else
          REASON="最終日付直前パターン（0でない→(1 rows affected)→日付）"
          EVIDENCE="$((prev3_idx+1))行目:${prev3},$((prev1_idx+1))行目:${prev1},$((last_idx+1))行目:${lines[$last_idx]}"
          FILE_NG=1
        fi
      fi
    fi
    # SQL実行結果確認
    if [ "$FILE_OK" -eq 0 ] && grep -q "Rows Affected: " "$LOG" && grep -q "SQL実行が正常に完了しました。" "$LOG"; then
      RA_LINE=$(grep -n "Rows Affected: " "$LOG" | tail -1)
      SQL_LINE=$(grep -n "SQL実行が正常に完了しました。" "$LOG" | tail -1)
      RA_LINENUM=$(echo "$RA_LINE" | cut -d: -f1)
      RA_TEXT=$(echo "$RA_LINE" | cut -d: -f2-)
      SQL_LINENUM=$(echo "$SQL_LINE" | cut -d: -f1)
      SQL_TEXT=$(echo "$SQL_LINE" | cut -d: -f2-)
      RA=$(echo "$RA_TEXT" | sed -E 's/.*Rows Affected: *([0-9]+).*/\1/')
      if [ "$RA" -gt 0 ]; then
        REASON="Rows Affected: $RA かつ SQL実行が正常に完了"
        EVIDENCE="${RA_LINENUM}行目:${RA_TEXT},${SQL_LINENUM}行目:${SQL_TEXT}"
        FILE_OK=1
      elif [ "$RA" -eq 0 ]; then
        REASON="SQL実行は正常終了だが Rows Affected: 0"
        EVIDENCE="${RA_LINENUM}行目:${RA_TEXT},${SQL_LINENUM}行目:${SQL_TEXT}"
        FILE_NG=1
      fi
    fi
    # 終了コード0 かつ 正常終了
    if [ "$FILE_OK" -eq 0 ]; then
      for ((i=0;i<${#lines[@]};i++)); do
        if [[ "${lines[$i]}" =~ ^[[:space:]]*0[[:space:]]*$ ]]; then
          for ((j=1;j<=5;j++)); do
            idx=$((i+j))
            [[ $idx -ge ${#lines[@]} ]] && break
            if [[ "${lines[$idx]}" =~ の正常終了 ]]; then
              REASON="終了コード0 かつ 正常終了"
              EVIDENCE="$((i+1))行目:${lines[$i]},$((idx+1))行目:${lines[$idx]}"
              FILE_OK=1
              break 2
            fi
          done
        fi
      done
    fi
    # HULFT判定パターンのリスト
    declare -A HULFT_PATTERNS
    HULFT_PATTERNS["転送"]="転送開始:転送正常終了:転送の正常終了:regex"
    HULFT_PATTERNS["集信正規"]="集信開始:集信正常終了:集信の正常終了:regex"
    HULFT_PATTERNS["集信スペース"]="HULFT 集信開始:HULFT 集信終了:集信の正常終了:plain"
    if echo "${lines[@]}" | grep -q "HULFT"; then
      for KEY in "${!HULFT_PATTERNS[@]}"; do
        [ "$FILE_OK" -eq 1 ] && break # 既にOKならスキップ
        IFS=":" read -r START END MSG TYPE <<< "${HULFT_PATTERNS[$KEY]}"
        if [[ "$TYPE" == "regex" ]]; then
          START_PATTERN="#< ?[ＨH][ＵU][ＬL][ＦF][ＴT]${START} ?>#"
          END_PATTERN="#< ?[ＨH][ＵU][ＬL][ＦF][ＴT]${END} ?>#"
          HAS_START=$(grep -Eq "$START_PATTERN" "$LOG" && echo 1 || echo 0)
          HAS_END=$(grep -Eq "$END_PATTERN" "$LOG" && echo 1 || echo 0)
          START_GREP="grep -n -E \"$START_PATTERN\""
          END_GREP="grep -n -E \"$END_PATTERN\""
          START_TEXT_GREP="grep -E \"$START_PATTERN\""
          END_TEXT_GREP="grep -E \"$END_PATTERN\""
        else
          HAS_START=$(grep -q "$START" "$LOG" && echo 1 || echo 0)
          HAS_END=$(grep -q "$END" "$LOG" && echo 1 || echo 0)
          START_GREP="grep -n \"$START\""
          END_GREP="grep -n \"$END\""
          START_TEXT_GREP="grep \"$START\""
          END_TEXT_GREP="grep \"$END\""
        fi
        if [ "$HAS_START" -eq 1 ] && [ "$HAS_END" -eq 1 ]; then
          START_LINE=$(eval $START_GREP "$LOG" | head -1 | cut -d: -f1)
          END_LINE=$(eval $END_GREP "$LOG" | head -1 | cut -d: -f1)
          START_TEXT=$(eval $START_TEXT_GREP "$LOG" | head -1)
          END_TEXT=$(eval $END_TEXT_GREP "$LOG" | head -1)
          REASON="HULFT${MSG}"
          EVIDENCE="${START_LINE}行目:${START_TEXT},${END_LINE}行目:${END_TEXT}"
          FILE_OK=1
          break
        elif [ "$HAS_START" -eq 1 ] || [ "$HAS_END" -eq 1 ]; then
          REASON="HULFT${START}または${END}の片方のみ検出"
          EVIDENCE=""
          [ "$HAS_START" -eq 1 ] && EVIDENCE+="開始検出:$(eval $START_GREP "$LOG" | head -1)"
          [ "$HAS_END" -eq 1 ] && EVIDENCE+="終了検出:$(eval $END_GREP "$LOG" | head -1)"
          FILE_NG=1
          break
        fi
      done
    fi
    # 判定
    if [ "$FILE_OK" -eq 1 ]; then
      echo "$LOG_NAME,$LINE_COUNT,$REASON,$EVIDENCE" >> "$OUT_OK"
    elif [ "$FILE_NG" -eq 1 ]; then
      echo "$LOG_NAME,$LINE_COUNT,$REASON,$EVIDENCE" >> "$OUT_NG"
    else
      echo "$LOG_NAME,$LINE_COUNT,判定不可," >> "$OUT_UNKNOWN"
    fi
  done
done
