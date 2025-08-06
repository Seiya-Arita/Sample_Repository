#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :通知預入明細抽出                          | HN_INFO.T_KT10130D_OBJ2
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :通知預金基本断面展開                      | HN_INFO.T_KT10120D_OBJ
#                    通知預入明細断面展開                      | HN_INFO.T_KT10130D_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/07/08 新規作成                                          | TSUKINOKI
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
/* 通知預入明細抽出 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT10130D_OBJ2]
SELECT A.* FROM ${INFO_DB}.[T_KT10130D_OBJ] AS A
INNER JOIN ${INFO_DB}.[T_KT10120D_OBJ] AS B
ON A.[作成基準日]=B.[作成基準日]
AND A.[TBN]=B.[TBN]
AND A.[CFB]=B.[CFB]
AND A.[KMK]=B.[KMK]
AND A.[KZB]=B.[KZB];
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
