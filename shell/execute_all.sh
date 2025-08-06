#!/bin/bash

INPUT_CSV="/home/ec2-user/kyo/Step1_TestList.csv"     # 入力CSVファイル名
OUTPUT_CSV="/home/ec2-user/kyo/script_results.csv"   # 出力CSVファイル名

# 出力CSVのヘッダー
echo "folder,script,args,exit_code,stdout,stderr" > "$OUTPUT_CSV"

# CSVを1行ずつ処理（ヘッダーを除く）
tail -n +2 "$INPUT_CSV" | while IFS=, read -r folder script args
do
    # 引数の空白とクォート処理
    folder=$(echo "$folder" | xargs)
    script=$(echo "$script" | xargs)
    args=$(echo "$args" | xargs)

    full_path="/home/control/$folder/$script"

    if [ ! -f "$full_path" ]; then
        echo "$folder,$script,\"$args\",-1,,\"File not found: $full_path\"" >> "$OUTPUT_CSV"
        continue
    fi

    # 一時ファイルに出力をキャプチャ
    stdout_file=$(mktemp)
    stderr_file=$(mktemp)

    if [ -z "$args" ]; then
        bash "$full_path" >"$stdout_file" 2>"$stderr_file"
    else
        bash "$full_path" $args >"$stdout_file" 2>"$stderr_file"
    fi

    exit_code=$?
    stdout=$(cat "$stdout_file" | tr '\n' ' ' | sed 's/"/""/g')
    stderr=$(cat "$stderr_file" | tr '\n' ' ' | sed 's/"/""/g')

    # クォートしてCSV出力
    echo "$folder,$script,\"$args\",$exit_code,\"$stdout\",\"$stderr\"" >> "$OUTPUT_CSV"

    rm -f "$stdout_file" "$stderr_file"
done

