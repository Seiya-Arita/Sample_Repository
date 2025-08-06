#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :世帯名寄せ最終マージ		| T_NY06000D_OBJ
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :世帯番号マージ				| T_NY06200D_OBJ
#                   :分離世帯番号マージ			| T_NY06500D_OBJ
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
INSERT INTO ${INFO_DB}.T_NY06000D_OBJ
SELECT
    A.[作成基準日],
    A.[店番],
    A.[ＣＩＦ番号],
    A.[統合ＣＩＦ番号],
    A.[代表ＣＩＦフラグ],
    A.[生死表示],
    DENSE_RANK()
        OVER(ORDER BY (CASE WHEN B.[統合ＣＩＦ番号] IS NULL
                            THEN A.[世帯番号]
                            ELSE LEFT(B.[世帯番号], datalength(B.[世帯番号])/4) + LEFT(C.[最大世帯番号], datalength(C.[最大世帯番号])/4)
                   END))     AS [世帯番号],
    ''                AS [世帯代表フラグ],
    A.[漢字氏名],
    A.[カナ氏名],
    A.[名寄せ用カナ氏名],
    A.[電話番号],
    A.[住所コード],
    A.[補助住所],
    A.[カナ氏名＿Ｎ],
    A.[名寄せ用カナ氏名＿Ｎ],
    A.[電話番号＿Ｎ],
    A.[補助住所＿Ｎ]
FROM ${INFO_DB}.T_NY06200D_OBJ      AS A
LEFT JOIN ${INFO_DB}.T_NY06500D_OBJ AS B
ON (A.[統合ＣＩＦ番号]=B.[統合ＣＩＦ番号])
CROSS JOIN (
    SELECT
        MAX([世帯番号])                [最大世帯番号]
    FROM ${INFO_DB}.T_NY06200D_OBJ
) AS C;
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
