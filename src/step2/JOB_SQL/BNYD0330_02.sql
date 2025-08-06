#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :年金有無                                  | HN_INFO.T_NY03000D_WK6
# フェーズ          :年金有無
# サイクル          :日次
# 参照テーブル      :顧客商品契約有無情報                      | HN_INFO.T_SN30100D_SRC001
#                   :名寄せ商品マスタ                          | HN_V_SEM.V_KT41000D_NYS
#                   :日付テーブル                              | HN_INFO.T_KT00060D_LOAD
# ------------------------------------------------------------------------------
# 2023-02-07        :新規作成                                  | Nagata
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
/* 年金有無 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_NY03000D_WK6
SELECT
   A.[作成基準日]                        AS [作成基準日],
   A.[店番]                              AS [店番],
   A.[ＣＩＦ番号]                        AS [ＣＩＦ番号],
   ''                                    AS [統合ＣＩＦ番号],
   ''                                    AS [代表ＣＩＦフラグ],
   0                                     AS [ＣＩＦ開設日],
   '0'                                   AS [事業資金貸出フラグ],
   '0'                                   AS [住宅ローンフラグ],
   '0'                                   AS [住公契約フラグ],
   0                                     AS [預かり資産残高],
   '0'                                   AS [給振フラグ],
   '1'                                   AS [年金フラグ],
   0                                     AS [公共料金自振数],
   0                                     AS [ローン取引数],
   0                                     AS [機能サービス数]
FROM (
       SELECT T2.[前日] AS [作成基準日],
             T1.[TBN]  AS [店番],
             T1.[CFB]  AS [ＣＩＦ番号],
             T1.[SFM]  AS [商品コード]
       FROM       ${DB_T_SRC}.T_SN30100D_SRC001  AS T1
       CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD     AS T2
       WHERE CAST(CAST(T2.[前前日] AS CHAR(8)) AS DATE) BETWEEN T1.[Start_Date] AND T1.[End_Date] AND
             T1.[Record_Deleted_Flag]=0 AND
             T1.[SFM] = '5020000000000'
     ) AS A
     INNER JOIN ${DB_T_SEM}.V_KT41000D_NYS AS B
     ON A.[商品コード] = B.[SHNCOD];
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
