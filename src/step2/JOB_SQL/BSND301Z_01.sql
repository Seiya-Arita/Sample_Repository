#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :顧客商品契約有無情報_中間ワーク           | T_SN30102D_OBJ
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :顧客商品契約有無情報                      | T_SN30102D_WK0~A
#                   :【顧客商品契約有無情報】BESTWAY           | T_SN25000D_OBJ
#                   :【顧客商品契約有無情報】STARIV            | T_SN25100D_OBJ
#                   :【顧客商品契約有無情報】X-NET             | T_SN25200D_OBJ
#                   :【顧客商品契約有無情報】DNP               | T_SN25300D_OBJ
#                   :【顧客商品契約有無情報】勘定系（流動性）  | T_SN24100D_OBJ
#                   :【顧客商品契約有無情報】でんさい          | T_SN25400D_OBJ
#                   :【顧客商品契約有無情報】保険              | T_SN25500D_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2021-08-05        :新規作成                                  | SVC TSUKINOKI
# 2023-03-17        :WKBテーブル追加                           | KODAMA
# 2024-01-25        :統合ＣＩＦ番号付与処理改善に伴う修正      | KODAMA
# 2024-03-21        :DNPテーブル追加                           | KODAMA
# 2024-02-08        :X-NET追加処理改善に伴う入力テーブル追加   | KOZAKI
# 2025-05-08        :協24-059-02（流動性/でんさい/保険追加）   | Shunya.M
# ===============================================================================
#
#  ＳＱＬ実行
#

sqlcmd -S ${SQL_SERVER} -d ${SQL_DB} -U ${SQL_USER} -P ${SQL_PASS} -f ${CHARSET} -t 0 -e -w 254 -b -N o -Q "
DECLARE @ExitCode INT;
DECLARE @ErrorCode INT;
SET @ExitCode = 0;
SELECT GETDATE() AS [DATE];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ****************************************************************** */
/* 顧客商品契約有無情報 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_SN30102D_OBJ]
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WK0] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WK1] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WK2] UNION
--    SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30102D_WK3] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WK4] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WK5] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WK6] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WK7] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WK8] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WK9] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WKA] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN30100D_WKB] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN25000D_OBJ] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN25100D_OBJ] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN25200D_OBJ] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN25300D_OBJ] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN24100D_OBJ] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN25400D_OBJ] UNION
SELECT [作成基準日], [店番], [ＣＩＦ番号], [商品コード] FROM ${INFO_DB}.[T_SN25500D_OBJ];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ######################################################################### */
/*                               通常の退出処理                              */
/* ######################################################################### */
SELECT GETDATE() AS [DATE];
SET @ExitCode = 0;
GOTO Final;
/* ######################################################################### */
/*                           エラー発生時の退出処理                          */
/* ######################################################################### */
ENDPT:
SELECT GETDATE() AS [DATE];
SET @ExitCode = 8;
GOTO Final;
/* ######################################################################### */
/*                    処理を終了し、終了コードを返却する                       */
/* ######################################################################### */
Final:
:EXIT(SELECT @ExitCode)
"


#
exit $?
