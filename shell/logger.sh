#!/bin/bash

log_exec() {
    local script_path="$1"  # 呼び出し元で明示的に渡す
    shift                   # 残りの引数だけ取得
    local args="$*"
    local log_file="/home/ec2-user/kyo/executed_scripts.csv"

    # CSV形式で出力（ダブルクォートで囲む）
    echo "\"${script_path}\",\"${args}\"" >> "$log_file"
}