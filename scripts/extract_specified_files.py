# ====================================
# 指定されたCSVファイルに基づいて、特定のフォルダから複数ファイルを一括コピーする
# 
# 1. フォルダ構成準備
# 作業ディレクトリ（例：C:\working）を用意する
#  
# コピー元のファイルは以下の場所に置く
# 　　C:\working\src\all
#  
# 補足：コピー先は自動作成
# 　　C:\working\src\copied\<YYYYMMDD_HHMMSS>
#  
# 2. list.csv の準備
# C:\working\list.csv を用意（ヘッダー必須）
# 　　※script_name は拡張子込みで記載
# ====================================

import os
import csv
import shutil
from datetime import datetime
import sys

working_dir = r"C:\working"

csv_path = os.path.join(working_dir, "list.csv")
source_base = os.path.join(working_dir, "src", "all")
copied_root = os.path.join(working_dir, "src", "copied")

if not os.path.exists(csv_path):
    print(f"❌ エラー: list.csv が存在しません → {csv_path}")
    sys.exit(1)

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
session_folder = os.path.join(copied_root, timestamp)

with open(csv_path, newline='', encoding='utf-8-sig') as csvfile:
    reader = csv.DictReader(csvfile, delimiter=',')
    print(f"ヘッダー: {reader.fieldnames}")  # デバッグ用にヘッダー出力
    for row in reader:
        folder = row['script_folder'].strip()
        filename = row['script_name'].strip()

        source_file = os.path.join(source_base, folder, filename)
        target_folder = os.path.join(session_folder, folder)
        os.makedirs(target_folder, exist_ok=True)
        dest_file = os.path.join(target_folder, filename)

        if os.path.exists(source_file):
            shutil.copy2(source_file, dest_file)
            print(f"✅ コピー成功: {source_file} → {dest_file}")
        else:
            print(f"⚠️ コピー元が見つかりません: {source_file}")
