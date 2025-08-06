#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【CC】顧客商品契約有無情報                | T_SN30100D_WK7
# フェーズ          :くまモンICカードアプリ利用者情報抽出
# サイクル          :日次
# 参照テーブル      :くまモンICカードアプリ会員情報            | T_SN41010D_SRC001
#                   :CDKA同一人名寄せ                          | V_MA00030D_SRCB01
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2023-01-23        :新規作成                                  | KODAMA
# 2023-06-06        :商品コード修正                            | KODAMA
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
/* 【CC】顧客商品有無情報作成（商品追加＿機能サービス） */
/*  くまモンICカードアプリ利用者情報抽出 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_SN30100D_WK7
SELECT
  T3.[作成基準日]      AS [作成基準日],
  T3.[店番]            AS [店番],
  T3.[ＣＩＦ番号]      AS [ＣＩＦ番号],
  T4.[統合ＣＩＦ番号]  AS [統合ＣＩＦ番号],
  'B020400000007'      AS [商品コード]
FROM
  (SELECT
      T2.[前日]        AS [作成基準日],
      T1.[TBN]         AS [店番],
      T1.[CFB]         AS [ＣＩＦ番号]
    FROM ${DB_T_SRC}.T_SN41010D_SRC001 AS T1
    CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD AS T2
    WHERE CAST(CAST(T2.[前日] AS CHAR(8)) AS DATE)
          BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
    GROUP BY [作成基準日], [店番], [ＣＩＦ番号]
  ) AS T3
INNER JOIN
  ${INFO_DB}.V_MA00030D_SRCB01 AS T4
ON  T3.[店番]       = T4.[店番]
AND T3.[ＣＩＦ番号] = T4.[ＣＩＦ番号];
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
