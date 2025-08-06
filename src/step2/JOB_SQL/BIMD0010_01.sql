#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :ＣＩＦマスタ					| T_IM00011D_WK
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :預金ＣＩＦ基本					| V_YK50060D_SRCB01
#                   :同一人名寄せ					| V_MA00030D_SRCB01
#                   :日付							| T_KT00060D_LOAD
#
# 変更履歴
# -------------------------------------------------------------------------
# 2021-10-15        :新規作成                       | ：meistier KIHARA
# 2025-02-03        :協24-044-02_情報系統合DB更改   | ：谷口
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
INSERT INTO ${INFO_DB}.[T_IM00011D_WK]
SELECT C.[前日] AS [作成基準日],
       A.[店番],
       A.[ＣＩＦ番号],
       B.[統合ＣＩＦ番号] AS [顧客番号],
       A.[顧客名＿拡張カナ] AS [カナ氏名],
       A.[顧客名漢字] AS [漢字氏名],
       A.[生年月日]
FROM
    (SELECT
        [TBN] AS [店番],
        [CFB] AS [ＣＩＦ番号],
        [KCHKNANAM] AS [顧客名＿拡張カナ],
        [KJM] AS [顧客名漢字],
        [BIR] AS [生年月日]
     FROM ${DB_T_SRC}.[T_YK50060D_SRC001]
     WHERE (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD]) BETWEEN [Start_Date] AND [End_Date]
    ) AS A
INNER JOIN ${INFO_DB}.[V_MA00030D_SRCB01] AS B
  ON (A.[店番] = B.[店番])
  AND (A.[ＣＩＦ番号] = B.[ＣＩＦ番号])
CROSS JOIN (SELECT [前日] FROM ${INFO_DB}.[T_KT00060D_LOAD]) AS C
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
