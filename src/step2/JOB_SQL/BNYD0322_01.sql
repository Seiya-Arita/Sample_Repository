#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :預かり資産残高＿外貨                      | HN_INFO.T_NY03002D_WK3
# フェーズ          :預かり資産残高
# サイクル          :日次
# 参照テーブル      :IDRZ外貨預金明細                          | HN_V_SRC.T_GK50030D_SRC001
#                   :日付テーブル                              | HN_INFO.T_KT00060D_LOAD
# 変更履歴
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
/* IDRZ外貨預金明細 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_NY03002D_WK3]
SELECT
   B.[前日]                        AS [作成基準日],
   A.[TBN]                         AS [店番],
   A.[CFB]                         AS [ＣＩＦ番号],
   A.[KCD]                         AS [科目],
   A.[KZB]                         AS [口座番号],
   A.[NOWECG]                      AS [残高]
FROM       ${DB_T_SRC}.[T_GK50030D_SRC001]  AS A
CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD]     AS B
WHERE CAST(CAST(B.[前前日] AS CHAR(8)) AS DATE) BETWEEN A.[Start_Date] AND A.[End_Date] AND
      A.[Record_Deleted_Flag]=0 AND
      A.[NOWECG]>0;
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
