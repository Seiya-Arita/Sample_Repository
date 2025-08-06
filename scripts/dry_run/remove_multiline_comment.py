# -----------------------------------------------------------------------------
# 処理概要:
# 本スクリプトは、指定ディレクトリ配下のファイルから
# ファイル先頭のコメント（/* ... */ブロックコメントや # コメント）を自動的に削除するバッチです。
#
# 主な処理内容:
#   1. 指定ディレクトリ以下の全ファイルを再帰的に探索
#   2. 各ファイルの先頭から「/* ... */」形式のブロックコメント（1つのみ）を削除
#   3. 続く先頭の#コメント行や空行も削除（ただし shebang "#!" 行は除外して残す）
#   4. 改行コードをLFに統一し、ファイルを上書き保存
#   5. 処理結果（コメント削除済ファイル）をコンソールに出力
#
# 注意事項:
#   - コメント削除はファイル冒頭部分のみを対象とします
#   - shebang行（#!）は必ず残します
#   - ファイルの内容や構造によっては意図しない箇所が削除される場合があるため注意してください
# -----------------------------------------------------------------------------

import os
import re
from config import DESTINATION_DIR

def remove_head_comments(file_path):
    with open(file_path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()

    new_lines = []
    i = 0

    # ステップ1: /* ... */ コメントブロックをスキップ（ファイル先頭のみ）
    if i < len(lines) and re.match(r'^\s*/\*', lines[i]):
        comment_block = False
        while i < len(lines):
            if re.search(r'/\*', lines[i]):
                comment_block = True
            if re.search(r'\*/', lines[i]):
                i += 1
                break
            i += 1

    # ステップ2: 先頭の # コメントを削除（ただし shebang は残す）
    while i < len(lines):
        line = lines[i]
        if line.startswith("#!"):
            new_lines.append(line)
            i += 1
            break
        elif line.strip().startswith("#"):
            i += 1
        elif line.strip() == "":
            i += 1
        else:
            break

    new_lines.extend(lines[i:])

    # ★ここでLFに統一
    new_lines = [line.rstrip('\r\n') + '\n' for line in new_lines]

    with open(file_path, "w", encoding="utf-8", newline='\n') as f:
        f.writelines(new_lines)

    print(f"〇 コメント削除: {file_path}")

def walk_and_process(root_folder):
    for dirpath, _, filenames in os.walk(root_folder):
        for filename in filenames:
            full_path = os.path.join(dirpath, filename)
            remove_head_comments(full_path)

if __name__ == "__main__":
    walk_and_process(DESTINATION_DIR)
