#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :確定世帯番号				| T_NY07000D_OBJ
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :世帯代表選定				| T_NY07200D_OBJ
#                   :最小旧代表に変わった世帯	| T_NY07804D_WK11
#                   :更新なし世帯再採番			| T_NY07806D_WK12
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
INSERT INTO ${INFO_DB}.T_NY07000D_OBJ
SELECT
    A.[作成基準日],
    A.[店番],
    A.[ＣＩＦ番号],
    A.[統合ＣＩＦ番号],
    A.[代表ＣＩＦフラグ],
    COALESCE(C.[最新世帯番号],B.[最新世帯番号],0) AS [世帯番号],
    COALESCE(B.[最新世帯代表フラグ],'') AS [世帯代表フラグ],
    COALESCE(B.[前日世帯番号],0) AS [前日世帯番号],
    COALESCE(B.[前日世帯代表フラグ],'') AS [前日世帯代表フラグ],
    COALESCE(B.[最新フラグ],'') AS [最新フラグ]
FROM ${INFO_DB}.T_NY07200D_OBJ AS A
LEFT JOIN ${INFO_DB}.T_NY07803D_WK11 AS B
    ON (A.[統合ＣＩＦ番号] = B.[統合ＣＩＦ番号])
LEFT JOIN ${INFO_DB}.T_NY07804D_WK12 AS C
    ON (A.[統合ＣＩＦ番号] = C.[統合ＣＩＦ番号]);
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
SELECT
    [最大世帯番号] AS [前日最大世帯番号]
FROM ${INFO_DB}.T_NY07801D_WK1;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
SELECT
    MAX([世帯番号]) AS [当日最大世帯番号]
FROM ${INFO_DB}.T_NY07000D_OBJ;
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
