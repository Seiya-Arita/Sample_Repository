#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :名寄せカナ氏名エラー		| T_NY05100D_OBJ
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :名寄せフォーマット変換		| T_NY04000D_OBJ
#                   :名寄せ対象外				| T_NY02900D_OBJ
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
INSERT INTO ${INFO_DB}.T_NY05100D_OBJ
SELECT
    COALESCE(A.[店番],B.[店番]) AS [店番],
    COALESCE(A.[ＣＩＦ番号],B.[ＣＩＦ番号]) AS [ＣＩＦ番号],
    COALESCE(A.[統合ＣＩＦ番号],B.[統合ＣＩＦ番号]) AS [統合ＣＩＦ番号]
FROM (
    SELECT
        [店番],
        [ＣＩＦ番号],
        [統合ＣＩＦ番号]
    FROM ${INFO_DB}.T_NY04000D_OBJ
    WHERE [名寄せ用カナ氏名] = ''
       OR [名寄せ用カナ氏名] LIKE '%ﾊｻﾝｼﾔ%'
       OR [名寄せ用カナ氏名] LIKE '%ｻｼｵｻｴ%'
) AS A
FULL OUTER JOIN ${INFO_DB}.T_NY02900D_OBJ AS B
ON (A.[統合ＣＩＦ番号]=B.[統合ＣＩＦ番号]);
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
