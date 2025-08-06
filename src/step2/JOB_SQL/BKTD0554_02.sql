#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【管理店】貸出先管理店情報                | HN_INFO.T_KT05540D_OBJ
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :ＣＩＦ残高融資                            | HN_INFO.T_KT12100D_OBJ
#                   :【管理店】管理店名寄せ情報                | HN_INFO.T_KT05580D_OBJ
#                   :【管理店】貸出先管理店情報（前日）        | HN_INFO.T_KT05540D_001
#                   :【管理店】統合番号親ＣＩＦ                | HN_INFO.T_KT05541D_WK
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/09/30 新規作成                                          | M.Shunya
# 2025/01/31 法人を名寄せしない                                | M.Shunya
# ===============================================================================
#
#  ＳＱＬ実行
#

sqlcmd -S ${SQL_SERVER} -d ${SQL_DB} -U ${SQL_USER} -P ${SQL_PASS} -f ${CHARSET} -t 0 -e -w 254 -b -N o -Q "
DECLARE @ExitCode INT;
DECLARE @ErrorCode INT;
SET @ExitCode = 0;
SELECT GETDATE() AS [DATE];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ****************************************************************** */
/* 【管理店】貸出先管理店情報 作成、抽出（事業資金貸出） */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT05540D_OBJ]
SELECT
     H.[前日]                 AS [作成基準日],
     C.[統合番号],
     E.[店番],
     E.[ＣＩＦ番号],
     ISNULL(D.[管理店番],0) AS [管理店番],
     C.[事業資金残高]         AS [残高],
     '04'                   AS [管理店番チャネル区分]
FROM (
    SELECT
        B.[統合番号],
        SUM(A.[事業資金貸出残高])  AS [事業資金残高]
    FROM ${INFO_DB}.[T_KT12100D_OBJ] AS A
    INNER JOIN ${INFO_DB}.[T_KT05580D_OBJ] AS B
    ON (A.[店番] = B.[店番]
    AND A.[ＣＩＦ番号] = B.[ＣＩＦ番号])
    WHERE A.[事業資金貸出残高] > 0
    GROUP BY B.[統合番号]
) AS C
LEFT JOIN (
    SELECT
          [統合番号],
          [管理店番]
      FROM ${INFO_DB}.[T_KT05540D_001]
     WHERE [作成基準日] = (SELECT [前前日] FROM ${INFO_DB}.[T_KT00060D_LOAD])
       AND [管理店番チャネル区分] = '04'
     ) AS D
ON (C.[統合番号] = D.[統合番号])
INNER JOIN ${INFO_DB}.[T_KT05541D_WK] AS E
ON (C.[統合番号] = E.[統合番号])
CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS H
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
