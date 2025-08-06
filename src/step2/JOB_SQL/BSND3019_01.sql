#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【CC】顧客商品契約有無情報                | T_SN30100D_WK9
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :BRKA債券明細S                             | V_SF50030D_SRCB01
#                   :【BestWay】投信口座残高                   | T_OM01020D_SEM001
#                   :HDRZ証券投信残高明細                      | V_SK51040D_SRCB01
#                   :HDRZ証券債券明細                          | V_SK51050D_SRCB01
#                   :CDKA同一人名寄せ                          | V_MA00030D_SRCB01
#                   :業務支援系商品マスタ                      | V_KT41000D_CC
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2021-08-23        :新規作成                                  | SVC TSUKINOKI
# 2023-12-15        :BESTWAY更改に伴い入力テーブル変更         | KODAMA
# 2024-02-08        :金銭信託連係に伴い作成NET変更             | KOZAKI
# 2025-06-03        :生保・損保の判定を別NET化(当処理から除外) | KODAMA
# ===============================================================================
#
#  ＳＱＬ実行
#

sqlcmd -S ${SQL_SERVER} -d ${SQL_DB} -U ${SQL_USER} -P ${SQL_PASS} -f ${CHARSET} -t 0 -e -w 254 -b -N o -Q "
DECLARE @ExitCode INT;
DECLARE @ErrorCode INT;
SET @ExitCode = 0;
SELECT GETDATE() AS DATE ;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;

/* ****************************************************************** */
/* 【CC】顧客商品有無情報作成（商品追加＿資産運用（商品ベース）） */
/* ****************************************************************** */

INSERT INTO ${INFO_DB}.T_SN30100D_WK9
SELECT
   DTE.[前日]         AS [データ基準日]
  ,Z.[店番]           AS [店番]
  ,Z.[ＣＩＦ番号]     AS [ＣＩＦ番号]
  ,B.[統合ＣＩＦ番号] AS [統合ＣＩＦ番号]
  ,Z.[商品コード]     AS [商品コード]
FROM
(
/* 公共債 */
    SELECT
      [店番]
     ,[ＣＩＦ番号]
     ,'90101' + CAST(dbo.FORMAT2([銘柄番号],'99999999') AS CHAR(8)) AS [商品コード]
    FROM  ${INFO_DB}.V_SF50030D_SRCB01
    WHERE [生死表示]=''
    GROUP BY [店番],[ＣＩＦ番号],'90101' + CAST(dbo.FORMAT2([銘柄番号],'99999999') AS CHAR(8))
    UNION ALL
/* 投資信託 */
    SELECT 
      A.[店番]       AS [店番]
     ,A.[ＣＩＦ番号] AS [ＣＩＦ番号]
     ,COALESCE(B.[商品コード],'9020000000000') AS [商品コード]
      FROM
      (
       (SELECT
          [HOSTBN]    AS [店番]
         ,[HOSCFB]    AS [ＣＩＦ番号]
         ,[FundCD]    AS [ファンドコード]
        FROM ${DB_T_SEM}.T_OM01020D_SEM001
        WHERE ( SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD )
              BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
        AND   [YakZan] > 0
       ) AS A
        LEFT JOIN
         (SELECT [コード階層区分４],[商品コード]
          FROM ${INFO_DB}.T_KT41000D_OBJ
          WHERE [コード階層区分１] = '9'
          AND [コード階層区分２] = '02')
        AS B
        ON A.[ファンドコード]=B.[コード階層区分４]
      )
    GROUP BY A.[店番],A.[ＣＩＦ番号],COALESCE(B.[商品コード],'9020000000000')
    UNION ALL
/* KFG投信 */
    SELECT [店番],[ＣＩＦ番号],COALESCE(B.[商品コード],'9070000000000') FROM (
    (SELECT [引落店番] AS [店番],[引落ＣＩＦ番号] AS [ＣＩＦ番号], [銘柄コード] AS [銘柄コード] FROM ${INFO_DB}.V_SK51040D_SRCB01) AS A
    LEFT JOIN
    (SELECT [コード階層区分４],[商品コード]
       FROM ${INFO_DB}.T_KT41000D_OBJ
       WHERE [削除フラグ]=''
       AND [コード階層区分１] = '9'
       AND [コード階層区分２] = '07')
     AS B
     ON RIGHT(REPLICATE('0',8) + CAST(A.[銘柄コード] AS VARCHAR(8)),8)=RIGHT(B.[コード階層区分４],8)
    )
    GROUP BY [店番],[ＣＩＦ番号],COALESCE(B.[商品コード],'9070000000000')
/* KFG債券 */
) AS Z
INNER JOIN
(
 SELECT
    [店番]
   ,[ＣＩＦ番号]
   ,[統合ＣＩＦ番号]
 FROM ${INFO_DB}.V_MA00030D_SRCB01
) AS B
ON  Z.[店番]=B.[店番]
AND Z.[ＣＩＦ番号]=B.[ＣＩＦ番号]
AND Z.[商品コード] IS NOT NULL
CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD AS DTE
;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;

/* ######################################################################### */
/*                               通常の退出処理                              */
/* ######################################################################### */
SELECT GETDATE() AS DATE ;
SET @ExitCode = 0;
GOTO Final;

/* ######################################################################### */
/*                           エラー発生時の退出処理                          */
/* ######################################################################### */
ENDPT:
SELECT GETDATE() AS DATE ;
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
