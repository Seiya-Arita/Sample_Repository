#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :名寄せ代表選定情報                        | HN_INFO.T_NY03000D_OBJ
# フェーズ          :名寄せ代表選定情報
# サイクル          :日次
# 参照テーブル      :名寄せ代表選定情報WK                      | HN_INFO.T_NY03000D_WK
#                   :YRKA流動性基本S                           | HN_V_SRC.T_YK50060D_SRC001
#                   :CDKA同一人名寄せ                          | HN_INFO.V_MA00030D_SRCB01
# ------------------------------------------------------------------------------
# 2023-02-07        :新規作成                                  | Nagata
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
/* 名寄せ代表選定情報 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_NY03000D_OBJ]
SELECT
   A.[作成基準日]                          AS [作成基準日],
   A.[店番]                                AS [店番],
   A.[ＣＩＦ番号]                          AS [ＣＩＦ番号],
   B.[統合ＣＩＦ番号]                      AS [統合ＣＩＦ番号],
   B.[代表ＣＩＦフラグ]                    AS [代表ＣＩＦフラグ],
   A.[ＣＩＦ開設日]                        AS [ＣＩＦ開設日],
   ISNULL(D.[事業資金貸出フラグ],'0')      AS [事業資金貸出フラグ],
   ISNULL(D.[住宅ローンフラグ],'0')        AS [住宅ローンフラグ],
   ISNULL(D.[住公契約フラグ],'0')          AS [住公契約フラグ],
   ISNULL(D.[預かり資産残高],0)            AS [預かり資産残高],
   ISNULL(D.[給振フラグ],'0')              AS [給振フラグ],
   ISNULL(D.[年金フラグ],'0')              AS [年金フラグ],
   ISNULL(D.[公共料金自振数],0)            AS [公共料金自振数],
   ISNULL(D.[ローン取引数],0)              AS [ローン取引数],
   ISNULL(D.[機能サービス数],0)            AS [機能サービス数]
FROM
    ( SELECT CAST(CAST(T2.[前日] AS CHAR(8)) AS DATE) AS [作成基準日],
             T1.[TBN]                      AS [店番],
             T1.[CFB]                      AS [ＣＩＦ番号],
             T1.[TRD]                      AS [ＣＩＦ開設日]
      FROM       ${DB_T_SRC}.[T_YK50060D_SRC001] AS T1
      CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD]    AS T2
      WHERE CAST(CAST(T2.[前日] AS CHAR(8)) AS DATE) BETWEEN T1.[Start_Date] AND T1.[End_Date]
        AND T1.[Record_Deleted_Flag]=0
        AND T1.[SSSHYJ]=''
    ) AS A
INNER JOIN
 ( SELECT [店番],[ＣＩＦ番号],[統合ＣＩＦ番号],[代表ＣＩＦフラグ] FROM ${INFO_DB}.[V_MA00030D_SRCB01] ) AS B
ON A.[店番] = B.[店番] AND A.[ＣＩＦ番号] = B.[ＣＩＦ番号]
LEFT JOIN
  ( SELECT
       C.[店番]                            AS [店番],
       C.[ＣＩＦ番号]                      AS [ＣＩＦ番号],
       MAX(C.[事業資金貸出フラグ])         AS [事業資金貸出フラグ],
       MAX(C.[住宅ローンフラグ])           AS [住宅ローンフラグ],
       MAX(C.[住公契約フラグ])             AS [住公契約フラグ],
       MAX(C.[預かり資産残高])             AS [預かり資産残高],
       MAX(C.[給振フラグ])                 AS [給振フラグ],
       MAX(C.[年金フラグ])                 AS [年金フラグ],
       MAX(C.[公共料金自振数])             AS [公共料金自振数],
       MAX(C.[ローン取引数])               AS [ローン取引数],
       MAX(C.[機能サービス数])             AS [機能サービス数]
    FROM ${INFO_DB}.[T_NY03000D_WK] AS C
    GROUP BY C.[店番],C.[ＣＩＦ番号]
  ) AS D
ON A.[店番] = D.[店番] AND A.[ＣＩＦ番号] = D.[ＣＩＦ番号];
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
