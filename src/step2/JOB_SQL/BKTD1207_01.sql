#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :融資計数マージ                            | HN_INFO.T_KT12070D_OBJ
# フェーズ          :ＣＩＦ残高
# サイクル          :日次
# 参照テーブル      :融資計数ワーク                            | HN_INFO.T_KT12070D_WKnn
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
SELECT GETDATE() AS DATE ;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ****************************************************************** */
/* 融資計数マージ */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK01;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK02;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK03;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK04;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK05;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK06;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK07;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK10;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK21;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK22;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK23;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK24;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK25;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK26;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK27;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK28;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK29;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK30;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK31;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK32;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK33;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK41;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK42;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK43;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK44;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK45;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK46;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK50;
INSERT INTO ${INFO_DB}.T_KT12070D_OBJ SELECT * FROM ${INFO_DB}.T_KT12070D_WK60;
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
