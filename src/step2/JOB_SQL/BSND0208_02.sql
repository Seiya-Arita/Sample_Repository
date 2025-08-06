#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :管理店変更依頼情報累積             | T_SN02080D_OBJ
# フェーズ          :テーブル作成
# サイクル          :月次
# 実行日            :
# 参照テーブル      :管理店変更依頼情報                 | T_SN02060D_LOAD
#                   :YRKA預金ＣＩＦ基本S                | T_YK50060D_SRC001
#
# 変更履歴
# -------------------------------------------------------------------------
# 2016-09-12        :新規作成                           | Human KOBAYASHI
# 2025-05-29        :入力変更（顧客基本→預金CIF基本）  | KOZAKI
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

INSERT INTO ${INFO_DB}.T_SN02080D_OBJ
SELECT
    C.[前日] AS [作成基準日],
    CASE WHEN B.[TBN] IS NULL
           THEN '1'
           ELSE '0'
    END AS [無効フラグ],
    A.[申請日],
    A.[申請者番号],
    A.[申請者名称],
    A.[フォーム名],
    A.[申請店番],
    A.[申請店名],
    A.[申請者所属番号],
    A.[申請者所属名称],
    A.[最終承認日],
    A.[最終承認者番号],
    A.[最終承認者名称],
    A.[ジョブ状態],
    A.[管理番号],
    A.[申請区分],
    A.[変更数],
    A.[明細番号],
    A.[勘定店番],
    A.[ＣＩＦ番号],
    A.[氏名],
    A.[変更後管理店番],
    A.[現状の管理店番],
    A.[連絡相手],
    A.[取引区分],
    A.[残高],
    A.[変更希望日],
    A.[変更区分],
    A.[変更理由],
    A.[交渉経緯入力]
FROM      ${INFO_DB}.T_SN02060D_LOAD AS A
LEFT JOIN (SELECT [TBN],[CFB] FROM ${DB_T_SRC}.T_YK50060D_SRC001
           WHERE (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD)
                 BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0) AS B
  ON A.[勘定店番]   = B.[TBN]
 AND A.[ＣＩＦ番号] = B.[CFB]
CROSS JOIN (
            SELECT
                [前日]
            FROM ${INFO_DB}.T_KT00060D_LOAD
           ) AS C
;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;

/* 統計情報取得は削除 */

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
