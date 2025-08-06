#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 登録テーブル名称  :本人確認依頼                   | T_SN03510D_OBJ
# フェーズ          :テーブル登録
# サイクル          :日次
# 参照テーブル      :YRKA預金ＣＩＦ基本S            | T_YK50060D_SRC001
#                   :YRKA流動性基本S                | T_YK51010D_SRC001
#                   :SDRZ自振管理                   | T_KT68250D_SRC001
#
# 変更履歴
# -------------------------------------------------------------------------
# 2022-03-18        :新規作成                       | SVC H.NODA
# 2022-08-08        :営業日対応                     | SVC S.TSUKINOKI
# 2024-09-18        :自振管理項目拡張               | KDS T.SASAKI
# 2025-01-10        :障害対応                       | TSUKINOKI
#                    (住宅金融公庫償還金 1810000)
# =========================================================================
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

WITH RankedData_T3 AS (
  SELECT
      SUBSTRING(T3.[ITSCOD],1,6) AS [委託者コード６ケタ],
      SUBSTRING(T3.[ITSCOD],7,4) AS [委託者コード枝番],
      LTRIM(RTRIM(T3.[ITSMEL])) AS [委託者名],
      LTRIM(RTRIM(T3.[NCRITSMEL])) AS [漢字委託者名],
      ROW_NUMBER() OVER (PARTITION BY SUBSTRING(T3.[ITSCOD],1,6)　ORDER BY SUBSTRING(T3.[ITSCOD],7,4)) as ranking_T3
  FROM (
      SELECT
          T1.[SLL],
          T1.[ITSCOD],
          T1.[ITSMEL],
          T1.[NCRITSMEL]
      FROM ${DB_T_SRC}.T_KT68250D_SRC001 AS T1
      CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD AS T2
      WHERE CAST(CAST(T2.[前日] AS CHAR(8)) AS DATE) BETWEEN T1.[Start_date] AND T1.[End_date]
        AND T1.[Record_Deleted_Flag] = 0
  ) AS T3
  WHERE NOT (T3.[SLL] BETWEEN '600' AND '699')
),
     RankedData_T7 AS (
  SELECT
      SUBSTRING(T7.[ITSCOD],1,3) AS [委託者コード３ケタ],
      SUBSTRING(T7.[ITSCOD],7,4) AS [委託者コード枝番],
      LTRIM(RTRIM(T7.[ITSMEL])) AS [委託者名],
      LTRIM(RTRIM(T7.[NCRITSMEL])) AS [漢字委託者名],
      ROW_NUMBER() OVER (PARTITION BY SUBSTRING(T7.[ITSCOD],1,3)　ORDER BY SUBSTRING(T7.[ITSCOD],7,4)) as ranking_T7
  FROM (
      SELECT
          T5.[SLL],
          T5.[ITSCOD],
          T5.[ITSMEL],
          T5.[NCRITSMEL]
      FROM ${DB_T_SRC}.T_KT68250D_SRC001 AS T5
      CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD AS T6
      WHERE CAST(CAST(T6.[前日] AS CHAR(8)) AS DATE) BETWEEN T5.[Start_date] AND T5.[End_date]
        AND T5.[Record_Deleted_Flag] = 0
  ) AS T7
  WHERE NOT (T7.[SLL] BETWEEN '600' AND '699')
    AND SUBSTRING(T7.[ITSCOD],1,3)='810'
)

INSERT INTO ${INFO_DB}.T_SN03510D_OBJ
SELECT
    Z.[レコード種別],
    Z.[レコードＩＤ],
    DTE.[前日],
    Z.[支店番号],
    Z.[科目],
    Z.[口座番号],
    Z.[委託者コード],
    Z.[委託者名],
    Z.[カセット番号],
    Z.[コマ番号],
    Z.[枝番],
    Z.[本人確認フラグ],
    CASE WHEN [電話番号]='' THEN '02' /* 電話番号未設定 */ ELSE '' END AS [本人確認結果],
    Z.[電話番号],
    Z.[予備],
    Z.[ＣＩＦ番号]
FROM (
    SELECT
        A.[レコード種別] AS [レコード種別],
        A.[レコードＩＤ] AS [レコードＩＤ],
        A.[作成日付] AS [作成日付],
        A.[支店番号] AS [支店番号],
        A.[科目] AS [科目],
        A.[口座番号] AS [口座番号],
        A.[委託者コード] AS [委託者コード],
        /*-------------------------------------*/
        /* 委託者コード頭9:行内自振から取得    */
        /* 上記以外       :自振管理から取得    */
        /*   住宅金融公庫償還金1810000の場合は */
        /*   3ケタ突合の委託者名を取得         */
        /* 取得不可はNULL挿入                  */
        /*-------------------------------------*/
        CASE WHEN SUBSTRING(A.[委託者コード],1,1)='9'
             THEN F.[行内自振＿委託者名]
             ELSE
                 CASE WHEN A.[委託者コード]='1810000' THEN
                     CASE WHEN G.[漢字委託者名]<>'' THEN G.[漢字委託者名]
                          ELSE G.[委託者名]
                     END
                 ELSE
                     CASE WHEN E.[漢字委託者名]<>'' THEN E.[漢字委託者名]
                          ELSE E.[委託者名]
                     END
                 END
        END AS [委託者名],
        A.[カセット番号] AS [カセット番号],
        A.[コマ番号] AS [コマ番号],
        A.[枝番] AS [枝番],
        A.[本人確認フラグ] AS [本人確認フラグ],
        A.[本人確認結果] AS [本人確認結果],
        CASE WHEN SUBSTRING(ISNULL(D.[携帯電話番号],''),1,3) IN ('090','080','070','060')
                  THEN ISNULL(dbo.Otranslate(D.[携帯電話番号],'-',''), '')
             WHEN SUBSTRING(ISNULL(D.[自宅電話番号],''),1,3) IN ('090','080','070','060')
                  THEN ISNULL(dbo.Otranslate(D.[自宅電話番号],'-',''), '')
             ELSE ''
        END AS [電話番号],
        A.[予備] AS [予備],
        ISNULL(D.[ＣＩＦ番号],0) AS [ＣＩＦ番号]
    FROM ${INFO_DB}.T_SN03500D_LOAD AS A
    LEFT JOIN (
        SELECT B.[店番],
               B.[ＣＩＦ番号],
               CASE WHEN B.[科目]='11' THEN '02'
                    WHEN B.[科目]='12' THEN '01'
                    ELSE B.[科目]
               END AS [科目],
               B.[口座番号],
               CASE WHEN SUBSTRING(ISNULL(C.[自宅電話番号],''),1,4) ='0800' THEN ''
                    ELSE ISNULL(C.[自宅電話番号],'')
               END AS [自宅電話番号],
               CASE WHEN SUBSTRING(ISNULL(C.[携帯電話番号],''),1,4) ='0800' THEN ''
                    ELSE ISNULL(C.[携帯電話番号],'')
               END AS [携帯電話番号]
        FROM (SELECT [店番],[ＣＩＦ番号],[科目],[口座番号] FROM ${INFO_DB}.V_YK51010D_SRCB01 WHERE [科目] IN ('11','12')) AS B
        INNER JOIN (SELECT [店番],[ＣＩＦ番号],[自宅電話番号],[携帯電話番号] FROM ${INFO_DB}.V_YK50060D_SRCB01) AS C
        ON B.[店番]=C.[店番] AND B.[ＣＩＦ番号]=C.[ＣＩＦ番号]
    ) AS D
    ON A.[支店番号]=D.[店番] AND A.[科目]=D.[科目] AND A.[口座番号]=D.[口座番号]

    /* 自振管理 */
    LEFT JOIN (
        SELECT
          [委託者コード６ケタ],
          [委託者コード枝番],
          [委託者名],
          [漢字委託者名]
        FROM
          RankedData_T3
        WHERE ranking_T3 = 1
    ) AS E
    ON SUBSTRING(A.[委託者コード],2,6) = E.[委託者コード６ケタ]

    /* 行内自振委託者 */
    LEFT JOIN (
        SELECT
            [ITSCOD] AS [行内自振＿委託者コード],
            LTRIM(RTRIM([ITSMEL])) AS [行内自振＿委託者名]
        FROM ${DB_T_SRC}.T_KT50060D_SRC001
        WHERE CONVERT(DATE, (SELECT [前日] FROM HN_INFO.T_KT00060D_LOAD)) BETWEEN [Start_date] AND [End_date]
    ) AS F
    ON SUBSTRING(A.[委託者コード],2,6) = SUBSTRING(dbo.FORMAT2([行内自振＿委託者コード],'9999999'),2,6)
    /*-----------------------------------------------*/
    /* 自振管理 2025-01-10                           */
    /* 住宅金融公庫償還金:1810000の場合は3ケタで突合 */
    /*-----------------------------------------------*/
    LEFT JOIN (
        SELECT
          [委託者コード３ケタ],
          [委託者コード枝番],
          [委託者名],
          [漢字委託者名]
        FROM
          RankedData_T7
        WHERE ranking_T7 = 1

    ) AS G
    ON SUBSTRING(A.[委託者コード],2,3) = G.[委託者コード３ケタ]
) AS Z
CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD AS DTE;
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
SELECT @ExitCode AS ExitCode;
RETURN;
"


#
exit $?
