#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :分離対象世帯				| T_NY06300D_OBJ
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :名寄せ世帯番号マージ		| T_NY06200D_OBJ
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
INSERT INTO ${INFO_DB}.[T_NY06300D_OBJ]
SELECT
    A.[作成基準日],
    A.[店番],
    A.[ＣＩＦ番号],
    A.[統合ＣＩＦ番号],
    A.[代表ＣＩＦフラグ],
    A.[生死表示],
    A.[世帯番号],
    '' AS [世帯代表フラグ],
    A.[漢字氏名],
    A.[カナ氏名],
    A.[名寄せ用カナ氏名],
    A.[電話番号],
    A.[住所コード],
    A.[補助住所],
    A.[カナ氏名＿Ｎ],
    A.[名寄せ用カナ氏名＿Ｎ],
    A.[電話番号＿Ｎ],
    A.[補助住所＿Ｎ],
    dbo.Otranslate(A.[補助住所＿Ｎ],'-','') AS [補助住所＿ＮＮ]
FROM ${INFO_DB}.[T_NY06200D_OBJ] AS A
INNER JOIN (
    SELECT
        C.[世帯番号]
    FROM (
        SELECT
            [世帯番号],
            [補助住所＿Ｎ]
        FROM ${INFO_DB}.[T_NY06200D_OBJ]
        GROUP BY [世帯番号],[補助住所＿Ｎ]
    ) AS C
    GROUP BY C.[世帯番号]
    HAVING COUNT(*) > 1
) AS B
ON (A.[世帯番号] = B.[世帯番号])
INNER JOIN (
    SELECT
        [世帯番号]
    FROM ${INFO_DB}.[T_NY06200D_OBJ]
    GROUP BY [世帯番号]
    HAVING COUNT(*) > 2
) AS D
ON (A.[世帯番号]=D.[世帯番号])
;
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
