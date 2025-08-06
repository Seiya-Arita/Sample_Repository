# -----------------------------------------------------------------------------
# 処理概要:
# 本スクリプトは、指定したExcelファイルの管理情報に基づき、
# ソースフォルダから必要なファイルのみを抽出・コピーするバッチです。
#
# 主な処理内容:
#   1. Excelファイル（管理台帳等）を読み込み、処理対象の条件（STEP種別やカテゴリ）でフィルタ
#   2. 指定されたソースディレクトリから、該当ファイルを検索
#   3. コピー先ディレクトリ（DESTINATION_DIR）に階層を維持してファイルをコピー
#   4. コピー・エラー・未存在ファイルなどの処理状況をコンソールに出力
#
# 注意事項:
#   - Excelのカラム構成やシート名が変更された場合は定数を修正してください
#   - EXCLUDED_CATEGORIES, STEP_CATEGORIES等の条件はconfig.pyで管理します
#   - 階層付きコピーのため、コピー先ディレクトリが事前になければ自動作成します
# -----------------------------------------------------------------------------

import os
import shutil
import pandas as pd
from config import DESTINATION_DIR, EXCEL_FILE_DIR, EXCLUDED_CATEGORIES, SHEET_NAME, SRC_ROOT_DIR, STEP_CATEGORIES

# Excelファイルの読み込み
df = pd.read_excel(EXCEL_FILE_DIR, header=None, sheet_name=SHEET_NAME, skiprows=2)
print(len(df))
print(df[2][0])

# コピー先ディレクトリがなければ作成
os.makedirs(DESTINATION_DIR, exist_ok=True)

# 処理開始
for row in range(len(df)):

    if (
        df[7][row] in EXCLUDED_CATEGORIES
        or df[5][row] not in STEP_CATEGORIES
    ):
        continue

    foleder_name = df[3][row][3:]
    file_name = df[2][row]

    source_path = os.path.join(SRC_ROOT_DIR, foleder_name, file_name)
    dest_folder = os.path.join(DESTINATION_DIR, foleder_name)

    if os.path.exists(source_path):
        try:
            os.makedirs(dest_folder, exist_ok=True)
            shutil.copy(source_path, dest_folder)
            print(f"〇 Copied: {source_path}")
        except Exception as e:
            print(f"△ Error copying {source_path}: {e}")
    else:
        print(f"✕ File not found: {source_path}")
