#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【顧客商品有無】九州FG証券オントレ         | HN_INFO.T_SN25100D_OBJ
# フェーズ          :九州FG証券オントレ商品契約有無を判定
# サイクル          :日次
# 参照テーブル      :九州FG証券顧客基本属性情報                 | HN_V_SRC.T_SK51110D_SRC001
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2025/05/08 新規作成                                           | Shunya.M
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
/* 顧客商品契約有無情報_九州FG証券オントレ作成 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_SN25100D_OBJ]
SELECT
    H.[前日]                        AS [作成基準日],
    A.[HOSTBN]                      AS [店番],
    A.[HOSCFB]                      AS [ＣＩＦ番号],
    'B030000000000'                 AS [商品コード]
FROM ${DB_T_SRC}.[T_SK51110D_SRC001] AS A
CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS H
WHERE A.[Record_Deleted_Flag] = 0
  AND (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD]) BETWEEN A.[Start_Date] AND A.[End_Date]
  AND (A.[KZPBEE] = 0
   OR A.[KZPBEE] > H.[前日])
  AND A.[CHLRYOKBN] = 'チャネル（ネット）を利用する'
GROUP BY H.[前日],A.[HOSTBN],A.[HOSCFB];
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
