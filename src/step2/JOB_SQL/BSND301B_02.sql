#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【CC】顧客商品契約有無情報                | T_SN30100D_WKB
# フェーズ          :ＩＢ・ＢＩＢ商品情報取得
# サイクル          :日次
# 参照テーブル      :ＩＢ・ＢＩＢ代表口座情報                  | T_SN50065D_SEM001
#                   :CDKA同一人名寄せ                          | V_MA00030D_SRCB01
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2023-03-17        :新規作成                                  | KODAMA
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
/*  ＩＢ・ＢＩＢ商品情報取得 */
/* ****************************************************************** */

INSERT INTO ${INFO_DB}.[T_SN30100D_WKB]
SELECT
  T3.[作成基準日]      AS [作成基準日],
  T3.[店番]            AS [店番],
  T3.[ＣＩＦ番号]      AS [ＣＩＦ番号],
  T4.[統合ＣＩＦ番号]  AS [統合ＣＩＦ番号],
  T3.[商品コード]      AS [商品コード]
FROM
  ( SELECT
      T2.[前日]        AS [作成基準日],
      T1.[DHKTBN]      AS [店番],
      T1.[DHKCFB]      AS [ＣＩＦ番号],
      CASE
        WHEN T1.[KYXBNG] <> ''   THEN 'B370100000000'
        ELSE 
          CASE
            WHEN T1.[KYAFSK] = 'A' THEN 'B370200000001'
            WHEN T1.[KYAFSK] = 'B' THEN 'B370200000002'
            WHEN T1.[KYAFSK] = 'L' THEN 'B370200000003'
            ELSE '' END
      END            AS [商品コード]
    FROM  ${DB_T_SEM}.[T_SN50065D_SEM001]    AS T1
    CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD]  AS T2
    WHERE CAST(CAST(T2.[前日] AS CHAR(8)) AS DATE)
          BETWEEN T1.[Start_Date] AND T1.[End_Date] AND T1.[Record_Deleted_Flag] = 0
    GROUP BY T2.[前日], T1.[DHKTBN], T1.[DHKCFB],
      CASE
        WHEN T1.[KYXBNG] <> ''   THEN 'B370100000000'
        ELSE 
          CASE
            WHEN T1.[KYAFSK] = 'A' THEN 'B370200000001'
            WHEN T1.[KYAFSK] = 'B' THEN 'B370200000002'
            WHEN T1.[KYAFSK] = 'L' THEN 'B370200000003'
            ELSE '' END
      END
  ) AS T3

INNER JOIN
  ${INFO_DB}.[V_MA00030D_SRCB01] AS T4
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
