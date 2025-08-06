# -----------------------------------------------------------------------------
# 処理概要:
# 本スクリプトは、指定ディレクトリ配下のシェルスクリプトファイルに対して、
# ログ出力用コード（logger.sh の呼び出し等）を自動挿入するバッチです。
#
# 主な処理内容:
#   1. 指定ディレクトリ以下を再帰的に走査し、全ファイルを対象に処理
#   2. 既にログ出力コード（logger.sh呼び出し等）が含まれていない場合のみ、LOGGING_CODEを先頭に挿入
#   3. シェバン（#!）行がある場合はその直後、sqlcmdから始まる場合は先頭に挿入
#   4. 改行コードをLFに統一し、ファイル末尾が改行で終わるよう補正
#
# 注意事項:
#   - 既にlogger.shやlog_exec等が記載済みの場合は重複挿入しません
#   - Pythonファイルは処理対象外となります
#   - LOGGING_CODEの内容は config.py で定義してください
# -----------------------------------------------------------------------------

import os
from config import DESTINATION_DIR, LOGGING_CODE

def should_inject(content: str) -> bool:
    """すでにlogger.shが含まれているかチェック"""
    return "source" not in content and "log_exec" not in content

def inject_logging_code(file_path: str):
    print(f"=====処理開始: {file_path}=====")
    with open(file_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    if not should_inject(content):
        print(f"スキップ（すでに挿入済）: {file_path}")
        return

    new_content = None
    if content.startswith("#!"):
        lines = content.splitlines()
        shebang = lines[0]
        new_content = "\n".join([shebang, LOGGING_CODE] + lines[1:])
    elif content.startswith("sqlcmd"):
        new_content = LOGGING_CODE + "\n" + content
    else:
        print(f"Shellではない: {file_path}")
        return  # ここで return しておく方が安全

    # 改行コードをLFに統一（CRLFやCRをLFへ変換）
    new_content = new_content.replace('\r\n', '\n').replace('\r', '\n')

    # ファイル末尾が改行で終わるよう保証
    if not new_content.endswith('\n'):
        new_content += '\n'

    with open(file_path, "w", encoding="utf-8", newline='\n') as f:
        f.write(new_content)

    print(f"=====挿入完了: {file_path}=====")

def walk_and_inject(root_folder: str):
    for dirpath, _, filenames in os.walk(root_folder):
        for filename in filenames:
            if filename.endswith(".py"):
                continue
            full_path = os.path.join(dirpath, filename)
            inject_logging_code(full_path)

if __name__ == "__main__":
    walk_and_inject(DESTINATION_DIR)
