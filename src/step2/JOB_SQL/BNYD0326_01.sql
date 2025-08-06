#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :預かり資産残高＿九州ＦＧ債券              | HN_INFO.T_NY03002D_WK7
# フェーズ          :預かり資産残高
# サイクル          :日次
# 参照テーブル      :九州FG証券債券明細                        | HN_V_SRC.T_SK51050D_SRC001
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
/* 九州FG証券債券明細 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_NY03002D_WK7]
SELECT
   B.[前日] AS [作成基準日],
   A.[HOSTBN] AS [店番],
   A.[HOSCFB] AS [ＣＩＦ番号],
   A.[HOSKMK] AS [科目],
   TRIM(CAST(dbo.FORMAT2(A.[HOSKZB],'ZZZZZZZZZZ9') AS CHAR(11))) AS [口座番号],
   A.[JQAHYG] AS [残高]
FROM ${DB_T_SRC}.[T_SK51050D_SRC001] AS A
CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS B
WHERE A.[MAKKJB] = B.[前前日] AND
      A.[JQAHYG] > 0;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ######################################################################### */
/*                               通常の退出処理                              */
/* ######################################################################### */
SELECT GETDATE() AS [DATE];
SET @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
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
