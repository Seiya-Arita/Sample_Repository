#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :名寄せ代表選定情報WK                      | HN_INFO.T_NY03000D_WK
# フェーズ          :名寄せ代表選定情報
# サイクル          :日次
# 参照テーブル      :名寄せ代表選定情報WK1                     | HN_INFO.T_NY03000D_WK1
#                   :名寄せ代表選定情報WK2                     | HN_INFO.T_NY03000D_WK2
#                   :名寄せ代表選定情報WK3                     | HN_INFO.T_NY03000D_WK3
#                   :名寄せ代表選定情報WK4                     | HN_INFO.T_NY03000D_WK4
#                   :名寄せ代表選定情報WK5                     | HN_INFO.T_NY03000D_WK5
#                   :名寄せ代表選定情報WK6                     | HN_INFO.T_NY03000D_WK6
#                   :名寄せ代表選定情報WK7                     | HN_INFO.T_NY03000D_WK7
#                   :名寄せ代表選定情報WK8                     | HN_INFO.T_NY03000D_WK8
#                   :名寄せ代表選定情報WK9                     | HN_INFO.T_NY03000D_WK9
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
SELECT GETDATE() AS DATE ;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ****************************************************************** */
/* 名寄せ代表選定情報WKサマリー */
/* ****************************************************************** */
/*T_NY03000D_WK1 */
INSERT INTO ${INFO_DB}.[T_NY03000D_WK] SELECT * FROM ${INFO_DB}.[T_NY03000D_WK1];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/*T_NY03000D_WK2 */
INSERT INTO ${INFO_DB}.[T_NY03000D_WK] SELECT * FROM ${INFO_DB}.[T_NY03000D_WK2];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/*T_NY03000D_WK3 */
INSERT INTO ${INFO_DB}.[T_NY03000D_WK] SELECT * FROM ${INFO_DB}.[T_NY03000D_WK3];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/*T_NY03000D_WK4 */
INSERT INTO ${INFO_DB}.[T_NY03000D_WK] SELECT * FROM ${INFO_DB}.[T_NY03000D_WK4];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/*T_NY03000D_WK5 */
INSERT INTO ${INFO_DB}.[T_NY03000D_WK] SELECT * FROM ${INFO_DB}.[T_NY03000D_WK5];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/*T_NY03000D_WK6 */
INSERT INTO ${INFO_DB}.[T_NY03000D_WK] SELECT * FROM ${INFO_DB}.[T_NY03000D_WK6];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/*T_NY03000D_WK7 */
INSERT INTO ${INFO_DB}.[T_NY03000D_WK] SELECT * FROM ${INFO_DB}.[T_NY03000D_WK7];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/*T_NY03000D_WK8 */
INSERT INTO ${INFO_DB}.[T_NY03000D_WK] SELECT * FROM ${INFO_DB}.[T_NY03000D_WK8];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/*T_NY03000D_WK9 */
INSERT INTO ${INFO_DB}.[T_NY03000D_WK] SELECT * FROM ${INFO_DB}.[T_NY03000D_WK9];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ######################################################################### */
/*                               通常の退出処理                              */
/* ######################################################################### */
SELECT GETDATE() AS DATE ;
SET @ExitCode = 0;
GOTO Final;
/* ######################################################################### */
/*                           エラー発生時の退出処理                          */
/* ######################################################################### */
ENDPT:
SELECT GETDATE() AS DATE ;
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
