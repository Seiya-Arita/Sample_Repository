#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :前日当日世帯マージ			| T_NY07802D_WK2
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :世帯代表選定				| T_NY07200D_OBJ
#                   :前日名寄インデックス		| T_NY08000D_SEM001
#                   :前日最大世帯番号			| T_NY07801D_WK1
#    
# 変更履歴
# -------------------------------------------------------------------------
# 2022-03-31        :新規作成                   | Shunya.M
# =========================================================================
#
#  ＳＱＬ実行
#

sqlcmd -S ${SQL_SERVER} -d ${SQL_DB} -U ${SQL_USER} -P ${SQL_PASS} -f ${CHARSET} -t 0 -e -w 300 -b -N o -Q "
DECLARE @ExitCode INT;
DECLARE @ErrorCode INT;
SET @ExitCode = 0;
SELECT GETDATE() AS [DATE];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
INSERT INTO ${INFO_DB}.T_NY07802D_WK2
SELECT
    A.[統合ＣＩＦ番号],
    COALESCE(B.[世帯番号],0) AS [前日世帯番号],
    COALESCE(B.[世帯代表フラグ],'') AS [前日世帯代表フラグ],
    LEFT(A.[世帯番号], datalength(A.[世帯番号])/4) + LEFT(C.[最大世帯番号], datalength(C.[最大世帯番号])/4) AS [当日世帯番号],
    A.[世帯代表フラグ] AS [当日世帯代表フラグ]
FROM ${INFO_DB}.T_NY07200D_OBJ AS A
LEFT JOIN (
    SELECT
        [TWGCFB] AS [統合ＣＩＦ番号],
        [STNO] AS [世帯番号],
        [HHDDHYFLG] AS [世帯代表フラグ]
    FROM ${DB_T_SEM}.T_NY08000D_SEM001 AS D
    CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD AS H
    WHERE D.[Record_Deleted_Flag] = 0
      AND CAST(CAST(H.[前前日] AS CHAR(8)) AS DATE) BETWEEN D.[Start_Date] AND D.[End_Date]
      AND D.[STNO] <> 0
      AND D.[DHYCIFFLG] = '1'
) AS B
ON (A.[統合ＣＩＦ番号] = B.[統合ＣＩＦ番号])
CROSS JOIN ${INFO_DB}.T_NY07801D_WK1 AS C;
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
