# 共通設定
import os

# マッピング仕様書配置ディレクトリ
FOLDER_PATH = "file/GCFR_IOteble_diff/GCFR_マッピング仕様書"
# 差分抽出先ディレクトリ
OUTPUT_EXCEL = "file/GCFR_IOteble_diff/GCFR_IOteble_diff_result.xlsx"
# 対象シート名
SHEET_NAME_TARGET = "マッピング定義書"
JOB_NAME_CELL = "U3"
INPUT_TABLE_CELL = "O3"
OUTPUT_SCHEMA_CELL = "K4"
OUTPUT_TABLE_CELL = "O4"
INPUT_COLUMNS_START_CELL = "B13"

# 中間View作成用 読み込みファイル
EXCEL_PATH = "file/GCFR_Step1_中間View/GCFR_入出力テーブル不一致一覧_Step1.xlsx"
# 中間View自動生成出力先ディレクトリ
OUTPUT_DIR = "file/GCFR_Step1_中間View/View_DDLs"

# DB接続情報
DB_CONN_STR = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=57.180.76.151;"
    "DATABASE=DDL_TEST;"
    "UID=DANNO;"
    "PWD=YourStrongPasswordHere@;"
    "TrustServerCertificate=yes;"
)
