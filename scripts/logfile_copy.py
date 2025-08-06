# ===============================
# 処理概要
# CSVファイルに記載されたジョブ名一覧に基づいて、
# 指定ディレクトリ内の対応する .log ファイルを別ディレクトリへコピーする
# コピー先ディレクトリには、すでに同名の .log ファイルが存在する可能性があるため、
# 実行前にそれらの既存ファイルをタイムスタンプ付きのバックアップフォルダ（old_YYYYMMDD_HHMMSS）に退避させる
# 
# How to use
# １．事前準備
# 　　　　・csv_pathのディレクトリにコピーしたいjob名をリスト化したcsvを配置
# 　　　　・source_dirのディレクトリにJOB_LOGのファイルを配置
# ２．当処理を実行
# ===============================
import csv
import os
import shutil
from datetime import datetime
from config import BASE_DIR

# 抽出対象となるジョブ名リストを記載したCSVファイルのパス
csv_path = fr"{BASE_DIR}\file\Step2\Step2_JobLogList.csv"
# 抽出元ディレクトリ
source_dir = fr"{BASE_DIR}\log\Step2\JOB_LOG"
# 抽出先ディレクトリ
destination_dir = fr"{BASE_DIR}\log\Step2\copied_logs"


# コピー先ディレクトリがなければ作成
os.makedirs(destination_dir, exist_ok=True)

# バックアップ（コピー前に既存ファイルを old_YYYYMMDD_HHMMSS に移動）
if os.path.exists(destination_dir):
    existing_files = [f for f in os.listdir(destination_dir) if f.endswith(".log")]
    if existing_files:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir = os.path.join(destination_dir, f"old_{timestamp}")
        os.makedirs(backup_dir, exist_ok=True)
        for f in existing_files:
            src_path = os.path.join(destination_dir, f)
            dst_path = os.path.join(backup_dir, f)
            shutil.move(src_path, dst_path)
            print(f"Moved to backup: {src_path} → {dst_path}")
else:
    os.makedirs(destination_dir, exist_ok=True)

# CSVを読み込みながら処理
with open(csv_path, newline='', encoding='utf-8-sig') as csvfile:
    reader = csv.reader(csvfile)
    for row in reader:
        if not row:
            continue
        base_name = row[0].strip()
        log_file = os.path.join(source_dir, f"{base_name}.log")
        dest_file = os.path.join(destination_dir, f"{base_name}.log")

        if os.path.exists(log_file):
            shutil.copy(log_file, dest_file)
            print(f"〇 Copied: {log_file} → {dest_file}")
        else:
            print(f"✕ Not Found: {log_file}")

