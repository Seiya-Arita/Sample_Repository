#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :世帯代表選定				| T_NY07200D_OBJ
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :世帯名寄せ最終マージ		| T_NY06000D_OBJ
#                   :世帯代表集計				| T_NY07100D_OBJ
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
INSERT INTO ${INFO_DB}.[T_NY07200D_OBJ]
SELECT
    A.[作成基準日],
    A.[店番],
    A.[ＣＩＦ番号],
    A.[統合ＣＩＦ番号],
    A.[代表ＣＩＦフラグ],
    A.[世帯番号],
    CASE WHEN [順位] = 1 THEN '1' ELSE '' END AS [世帯代表フラグ],
    A.[生死表示] AS [RANK生死表示],
    ISNULL(B.[事業資金貸出フラグ],'0') AS [RANK事業資金貸出フラグ],
    ISNULL(B.[住宅ローンフラグ],'0') AS [RANK住宅ローンフラグ],
    ISNULL(B.[住公契約フラグ],'0') AS [RANK住公契約フラグ],
    ISNULL(B.[預かり資産残高１００万],0) AS [RANK預かり資産残高１００万],
    ISNULL(B.[給振フラグ],'0') AS [RANK給振フラグ],
    ISNULL(B.[年金フラグ],'0') AS [RANK年金フラグ],
    ISNULL(B.[公共料金自振数],0) AS [RANK公共料金自振数],
    ISNULL(B.[ローン取引数],0) AS [RANKローン取引数],
    ISNULL(B.[機能サービス数],0) AS [RANK機能サービス数],
    ISNULL(B.[ＣＩＦ開設日],0) AS [RANKＣＩＦ開設日],
    A.[店番] * 100000000 + A.[ＣＩＦ番号] AS [RANK顧客番号],
    ISNULL(B.[ＣＩＦ数],0) AS [ＣＩＦ数],
    RANK() OVER (
        PARTITION BY [世帯番号]
            ORDER BY [RANK生死表示],
                     [RANK事業資金貸出フラグ] DESC,
                     [RANK住宅ローンフラグ] DESC,
                     [RANK住公契約フラグ] DESC,
                     [RANK預かり資産残高１００万] DESC,
                     [RANK給振フラグ] DESC,
                     [RANK年金フラグ] DESC,
                     [RANK公共料金自振数] DESC,
                     [RANKローン取引数] DESC,
                     [RANK機能サービス数] DESC,
                     [RANKＣＩＦ開設日] DESC,
                     [RANK顧客番号] DESC
        ) AS [順位]
FROM ${INFO_DB}.[T_NY06000D_OBJ] AS A
LEFT JOIN ${INFO_DB}.[T_NY07100D_OBJ] AS B
ON (A.[統合ＣＩＦ番号] = B.[統合ＣＩＦ番号]);
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
