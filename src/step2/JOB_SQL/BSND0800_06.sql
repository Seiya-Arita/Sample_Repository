#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 追加テーブル名称  :                   | T_SN00801D_WK4
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :                   | T_SN00801D_WK2
# 参照テーブル      :                   | T_SN00801D_WK3
#
# 備考              :ＦＧ証券用顧客口座情報作成
#
# 変更履歴
# -------------------------------------------------------------------------
# 2023-02-03        :新規作成           | KDS K.Setoguchi
#
# =========================================================================
#
#  ＳＱＬ実行
#

sqlcmd -S ${SQL_SERVER} -d ${SQL_DB} -U ${SQL_USER} -P ${SQL_PASS} -f ${CHARSET} -t 0 -e -b -N o -Q "
DECLARE @ExitCode INT;
DECLARE @ErrorCode INT;
SET @ExitCode = 0;
SELECT GETDATE() AS [DATE];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ******************************************************/
/*  06_ＮＩＳＡ契約店番ＣＩＦ番号グループ化 */
/* ******************************************************/
INSERT INTO ${INFO_DB}.T_SN00801D_WK4
SELECT
     C.[店番] AS [店番],
     C.[ＣＩＦ番号] AS [ＣＩＦ番号],
     '' AS [科目],
     0 AS [口座番号]
FROM (
    SELECT
         CASE WHEN A.[店番] IS NULL
           THEN B.[店番]
           ELSE A.[店番]
         END AS [店番],
         CASE WHEN A.[ＣＩＦ番号] IS NULL
           THEN B.[ＣＩＦ番号]
           ELSE A.[ＣＩＦ番号]
         END AS [ＣＩＦ番号]
    FROM ${INFO_DB}.T_SN00801D_WK2 A
    FULL JOIN ${INFO_DB}.T_SN00801D_WK3 B
         ON A.[店番] = B.[店番]
        AND A.[ＣＩＦ番号] = B.[ＣＩＦ番号]
) C
GROUP BY C.[店番], C.[ＣＩＦ番号];
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
