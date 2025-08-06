#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :世帯名寄せ採番				| T_NY06100D_OBJn	
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :名寄せフォーマット変換		| T_NY04000D_OBJ
#                   :名寄せカナ氏名エラー		| T_NY05100D_OBJ
#                   :住所コードエラー			| T_NY05200D_OBJ
#                   :補助住所エラー				| T_NY05300D_OBJ
#                   :電話番号エラー				| T_NY05400D_OBJ
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
INSERT INTO ${INFO_DB}.[T_NY06100D_${EXT_ID}]
SELECT
    A.[統合ＣＩＦ番号],
    DENSE_RANK() OVER(ORDER BY ${NAYOSE_KEY}) AS [世帯番号]
FROM ${INFO_DB}.[T_NY04000D_OBJ] AS A
LEFT JOIN (
    SELECT [統合ＣＩＦ番号] FROM ${INFO_DB}.[T_NY05100D_OBJ]
    UNION
    SELECT [統合ＣＩＦ番号] FROM ${INFO_DB}.[T_NY05200D_OBJ]
    UNION
    SELECT [統合ＣＩＦ番号] FROM ${INFO_DB}.[${CHK_TBL}]
) AS B
ON (A.[統合ＣＩＦ番号]=B.[統合ＣＩＦ番号])
WHERE B.[統合ＣＩＦ番号] IS NULL;
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
