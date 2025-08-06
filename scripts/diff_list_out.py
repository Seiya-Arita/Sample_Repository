import pandas as pd
import os
from glob import glob
import re

def is_japanese(text):
    return bool(re.search(r'[\u3040-\u30FF\u4E00-\u9FFF]', text))

def is_roman(text):
    return not is_japanese(text) and text.strip() != ''

base_dir = r"C:\working\Higo_bank\Analyze_tool\file\マッピング仕様書"
diff_dir = os.path.join(base_dir, "diff_list")
os.makedirs(diff_dir, exist_ok=True)

excel_files = [
    f for f in glob(os.path.join(base_dir, "*.xlsx"))
    if not os.path.basename(f).startswith("~$")
]

for file_path in excel_files:
    df = pd.read_excel(
        file_path,
        header=None,
        skiprows=7,
        sheet_name="マッピング定義書",
        engine="openpyxl"
    )
    diff_rows = []
    for idx, row in df.iterrows():
        a_val = '' if pd.isna(row[0]) else str(row[0])
        b_val = '' if pd.isna(row[1]) else str(row[1]).strip()
        g_val = '' if pd.isna(row[6]) else str(row[6]).strip()
        l_val = '' if pd.isna(row[11]) else str(row[11]).strip()

        # A列（項番）が空ならループ終了
        if a_val == '':
            break
        if b_val == '' and g_val != '':
            continue

        # B列が日本語の場合はスキップ
        if is_japanese(b_val):
            #print(f"項番: {a_val} はB列が日本語のためスキップ: B列={b_val}")
            continue

        # B列・G列どちらも日本語以外（≒ローマ字）なら比較
        if is_roman(b_val) and is_roman(g_val):
            #print(f"項番: {a_val}, 入力項目: {b_val}, 出力項目: {g_val}, 出力項目(論理名): {l_val}")
            if b_val != g_val:
                #print("→ 差分あり（出力）")
                diff_rows.append([a_val, b_val, g_val, l_val])
            #else:
                #print("→ 差分なし")
                
            continue

        # それ以外は比較対象外
        #print(f"項番: {a_val} は比較対象外: B列={b_val}, G列={g_val}")

    if diff_rows:
        out_csv = os.path.join(
            diff_dir,
            "diff_" + os.path.splitext(os.path.basename(file_path))[0] + ".csv"
        )
        df_out = pd.DataFrame(
            diff_rows,
            columns=["項番", "入力項目", "出力項目", "出力項目(論理名)"]
        )
        df_out.to_csv(out_csv, index=False, encoding='utf-8-sig')
        print(f"出力：{out_csv}")
    else:
        print(f"差分なし：{os.path.basename(file_path)}")