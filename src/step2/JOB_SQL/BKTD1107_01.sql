#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :預金計数マージ                            | HN_INFO.T_KT11070D_OBJ
# フェーズ          :ＣＩＦ残高
# サイクル          :日次
# 参照テーブル      :預金計数ワーク                            | HN_INFO.T_KT11070D_WKnn
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
/* 預金計数マージ */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK01;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK02;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK03;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK04;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK05;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK06;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK10;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK11;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK12;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK13;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK14;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK15;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK16;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK17;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK20;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK18;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK19;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK30;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK21;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK31;
INSERT INTO ${INFO_DB}.T_KT11070D_OBJ SELECT * FROM ${INFO_DB}.T_KT11070D_WK22;
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
