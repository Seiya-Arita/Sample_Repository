#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :口座情報					| T_IM00010D_OBJ

# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :ＣＩＦワーク					| T_IM00011D_WK
#                   :定期性情報 					| V_KT61050D_SEMB01
#                   :定期性口座 					| V_YK51340D_SRCB00
#
# 変更履歴
# -------------------------------------------------------------------------
# 2021-10-15        :新規作成                       | ：meistier KIHARA
# 2021-12-20        :重複対応                       | ：meistier KIHARA
# 2022-09-22        :重複対応                       | ：meistier KIHARA
# 2022-09-30        :口座のみ取り込み               | ：meistier KIHARA
# 2022-10-11        :自動継続対応                   | ：meistier KIHARA
# 2023-02-06        :口座のみ取り込み解約対応       | ：meistier KIHARA
# 2025-02-04        :協24-044-02_情報系統合DB更改   | ：谷口
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
/* ****************************************************************** */
/*   ST00                                                 */
/* ****************************************************************** */
--YRKA通知預入明細S
INSERT INTO ${INFO_DB}.T_IM00012D_WK
SELECT
    V1.[TBN] AS [店番],
    V1.[CFB] AS [ＣＩＦ番号],
    V1.[KMK] AS [科目],
    CASE
        WHEN V1.[KZB] <> 0 THEN V1.[KZB]
        ELSE V1.[SOXBNG] END AS [口座番号],
    V1.[MSB] AS [明細番号],
    0 AS [預入日],
    '' AS [子定期表示],
    V1.[SSSHYJ] AS [生死表示],
    V1.[TUCSSYSRI] AS [通帳証書種類]
FROM
  ${DB_T_SRC}.T_YK51330D_SRC001 AS V1
WHERE
  (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD)
  BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
  AND ([KJKKNB] = 0 OR [KJKKNB] > (SELECT [前月末日] FROM ${INFO_DB}.T_KT00060D_LOAD))
;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
--YRKA定期預入明細S
INSERT INTO ${INFO_DB}.T_IM00012D_WK
SELECT
    V1.[TBN] AS [店番],
    V1.[CFB] AS [ＣＩＦ番号],
    V1.[KMK] AS [科目],
    CASE
        WHEN V1.[KZB] <> 0 THEN V1.[KZB]
        ELSE V1.[SOXBNG] END AS [口座番号],
    V1.[MSB] AS [明細番号],
    V1.[YNB] AS [預入日],
    V1.[KTQHYJ] AS [子定期表示],
    V1.[SSSHYJ] AS [生死表示],
    V1.[TUCSSYSRI] AS [通帳証書種類]
FROM
  ${DB_T_SRC}.T_YK51350D_SRC001 AS V1
WHERE
  (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD)
  BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
  AND ([KJKKNB] = 0 OR [KJKKNB] > (SELECT [前月末日] FROM ${INFO_DB}.T_KT00060D_LOAD))
;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
--YRKA定期積金基本S
INSERT INTO ${INFO_DB}.T_IM00012D_WK
SELECT
    V1.[TBN] AS [店番],
    V1.[CFB] AS [ＣＩＦ番号],
    V1.[KMK] AS [科目],
    V1.[KZB] AS [口座番号],
    0 AS [明細番号],
    0 AS [預入日],
    '' AS [子定期表示],
    V1.[SSSHYJ] AS [生死表示],
    V1.[TUCSSYSRI] AS [通帳証書種類]
FROM
  ${DB_T_SRC}.T_YK51470D_SRC001 AS V1
WHERE
  (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD)
  BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
  AND ([KZPBEE] = 0 OR [KZPBEE] > (SELECT [前月末日] FROM ${INFO_DB}.T_KT00060D_LOAD))
;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ****************************************************************** */
/*   ST01                                                 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_IM00010D_WK2
SELECT 0 AS [作成基準日],
       A.[店番],
       A.[科目],
       A.[口座番号],
       A.[ＣＩＦ番号] AS [店別顧客番号],
       0  AS [顧客番号],
       '' AS [カナ氏名],
       '' AS [漢字氏名],
       0 AS [生年月日]
FROM  ${INFO_DB}.T_IM00012D_WK AS A
LEFT JOIN
    (SELECT [店番], [科目], [口座番号],[明細番号],[子定期表示],[預入日],COUNT(*) as [件数]
    FROM  ${INFO_DB}.T_IM00012D_WK
    WHERE SUBSTRING([通帳証書種類],1,1)<>'0'
    GROUP BY [店番],[科目],[口座番号],[明細番号],[子定期表示],[預入日]
    HAVING COUNT(*)>1) AS B
    ON A.[店番]=B.[店番]
    AND A.[科目]=B.[科目]
    AND A.[口座番号]=B.[口座番号]
LEFT JOIN
    (SELECT [店番], [科目], [口座番号],COUNT(*) as [件数]
    FROM  ${INFO_DB}.T_IM00012D_WK
    WHERE  SUBSTRING([通帳証書種類],1,1)='0'
    GROUP BY [店番],[科目],[口座番号]
    HAVING COUNT(*)>1) AS C
    ON A.[店番]=C.[店番]
    AND A.[科目]=C.[科目]
    AND A.[口座番号]=C.[口座番号]
WHERE NOT (B.[店番] IS NOT  NULL AND [生死表示]=1)
AND   NOT (C.[店番] IS NOT  NULL AND [生死表示]=1)
GROUP BY A.[店番],A.[科目],A.[口座番号],A.[ＣＩＦ番号]
;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ****************************************************************** */
/*   ST02                                                 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_IM00010D_WK2
SELECT 0 AS [作成基準日],
       A.[店番],
       A.[科目],
       A.[口座番号],
       A.[ＣＩＦ番号] AS [店別顧客番号],
       0  AS [顧客番号],
       '' AS [カナ氏名],
       '' AS [漢字氏名],
       0 AS [生年月日]
FROM  ${INFO_DB}.V_YK51340D_SRCB02 AS A
WHERE [口座番号]<>0 AND [預入件数]=0 AND [まとめ預入件数]=0
;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ****************************************************************** */
/*   ST02                                                 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_IM00010D_OBJ
SELECT B.[作成基準日],
       A.[店番],
       A.[科目],
       A.[口座番号],
       A.[ＣＩＦ番号],
       B.[顧客番号],
       B.[カナ氏名],
       B.[漢字氏名],
       B.[生年月日]
FROM ${INFO_DB}.T_IM00010D_WK2 AS A
INNER JOIN ${INFO_DB}.T_IM00011D_WK     AS B
  ON (A.[店番] = B.[店番])
  AND (A.[ＣＩＦ番号] = B.[ＣＩＦ番号])
GROUP BY B.[作成基準日],A.[店番],A.[科目],A.[口座番号],A.[ＣＩＦ番号],B.[顧客番号],B.[カナ氏名],B.[漢字氏名],B.[生年月日]
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
