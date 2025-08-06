import csv
import os

# CSVファイル名（同じディレクトリにあると想定）
csv_file = 'file\\dummy_job.csv'

# 出力先ディレクトリ（Windowsの相対パスや絶対パスOK）
output_dir = 'src\\dummy_job'
os.makedirs(output_dir, exist_ok=True)

with open(csv_file, newline='', encoding='utf-8') as f:
    reader = csv.reader(f)
    for row in reader:
        if not row:
            continue
        script_name = row[0].strip()
        if not script_name:
            continue

        # .sh 拡張子なし
        file_path = os.path.join(output_dir, script_name)

        # LFで書き出す（newline='\n'）
        with open(file_path, 'w', encoding='utf-8', newline='\n') as script_file:
            script_file.write('#!/bin/bash\nexit 0\n')

print(f"スクリプトが '{output_dir}' フォルダに作成されました。")
