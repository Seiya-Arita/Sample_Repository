#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :預かり資産残高＿投信                      | ${INFO_DB}.T_NY03002D_WK4
# フェーズ          :預かり資産残高
# サイクル          :日次
# 参照テーブル      :投信口座残高属性情報                      | HN_V_SEM.T_OM01020D_SEM001
#                   :日付テーブル                              | HN_INFO.T_KT00060D_LOAD
# ------------------------------------------------------------------------------
# 2023-02-07        :新規作成                                  | Nagata
# 2023-07-21        :結合条件修正                              | Tsukinoki
# 2023-12-24        :BESTWAY定例バージョンアップ               | M.Shunya
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
/* 預り残高(azan)                                                     */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_NY03002D_WK4
/*ＣＩＦ番号取得*/
SELECT
    H.[前日] AS [作成基準日],
    A.[HOSTBN] AS [店番],
    A.[HOSCFB] AS [ＣＩＦ番号],
    A.[HOSKMK] AS [科目],
    TRIM(CAST(dbo.FORMAT2(A.[ActNO],'ZZZZZZZZZZ9') AS CHAR(11))) AS [口座番号], /* ActNo */
    A.[HyoukaKin] AS [残高]
FROM ${DB_T_SEM}.T_OM01020D_SEM001 AS A
CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD AS H
WHERE CAST(CAST(H.[前前日] AS CHAR(8)) AS DATE) BETWEEN A.[Start_date] AND A.[End_date]
  AND A.[Record_Deleted_Flag]=0
  AND A.[HyoukaKin]>0
  AND A.[HOSTBN]<>0;
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
