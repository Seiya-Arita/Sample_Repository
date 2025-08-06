# 共通設定
import os

# プロジェクトのベースディレクトリ（起点のパス）
BASE_DIR = r"C:\\working\\Higo_bank\\Analyze_tool"

# 移行先リスト一覧のExcelファイル名
EXCEL_FILE_NAME = "20250730_移行資産_arita.xlsx"
# 移行先リスト一覧のExcelファイルのシート名
SHEET_NAME = "(20250704時点)移行資産"
# Excelファイル(ディレクトリ込み)
EXCEL_FILE_DIR = os.path.join(BASE_DIR, "file", EXCEL_FILE_NAME)
# Excelファイルの除外対象のカテゴリ一覧
EXCLUDED_CATEGORIES = (
    'エクスポート',
    'ロード',
    'テーブル',
    'VIEW',
    'Step1未使用',
    '対象外',
)

# Stepの定義
STEP1 = (1,)
STEP2 = (2, 3)
STEP3 = (4,)
STEP4 = (5, 6)
# Stepの設定
STEP_CATEGORIES = STEP2

# ソースのディレクトリ
# コピー元ディレクトリ(最新ソースからローカルに落としたファイル)
SRC_ROOT_DIR = os.path.join(BASE_DIR, "src", "all")
# コピー先ディレクトリ
DESTINATION_DIR = os.path.join(BASE_DIR, "src", "Step2_ジョブ実行テスト用", "20250730_GCFR")

# ログ出力用の設定値
LOGGING_CODE = f'''. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${{BASH_SOURCE[0]:-${{0}}}}")"

log_exec "$script_path" "$@"
'''
