#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :新代表に変わった世帯		| T_NY07803D_WK6
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :代表変更なし世帯			| T_NY07803D_WK3
#                   :更新なし新代表抽出２		| T_NY07804D_WK5
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
INSERT INTO ${INFO_DB}.[T_NY07803D_WK6]
SELECT
    A.[統合ＣＩＦ番号],
    A.[前日世帯番号],
    A.[前日世帯代表フラグ],
    COALESCE(B.[前日世帯番号],A.[最新世帯番号]) AS [最新世帯番号],
    A.[最新世帯代表フラグ] AS [最新世帯代表フラグ],
    CASE WHEN B.[最新世帯番号] IS NOT NULL
         THEN '1'
         ELSE A.[最新フラグ]
    END AS [最新フラグ]
FROM ${INFO_DB}.[T_NY07803D_WK3] AS A
LEFT JOIN ${INFO_DB}.[T_NY07804D_WK5] AS B
ON (A.[最新世帯番号] = B.[最新世帯番号]);
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
