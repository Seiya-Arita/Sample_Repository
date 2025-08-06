#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :ＣＩＦ動態情報縦持ち（SCOPE）  | T_KT18050D_OBJ
#                      他銀行系クレジット＿件数  （項目コード：4001）
#                      信販系クレジット＿件数    （項目コード：4003）
#                      流通系クレジット＿件数    （項目コード：4005）
#                      メーカー系クレジット＿件数（項目コード：4007）
#                      その他クレジット＿件数    （項目コード：4009）
# フェーズ          :テーブル作成
# サイクル          :月次
# 参照テーブル      :流動性入払                     | T_YK50010D_SRC001
#                   :クレジット会社情報             | T_CG0003E
#                   :日付テーブル                   | T_KT00060D_LOAD
#
# 変更履歴
# -------------------------------------------------------------------------
# 2024-10-21        :新規作成                       | K.Setoguchi
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
INSERT INTO ${INFO_DB}.T_KT18050M_WK1
SELECT
    D.[作成基準日]                    AS [作成基準日],
    CASE
      WHEN D.[分類コード]=2  THEN '4001' 
      WHEN D.[分類コード]=1  THEN '4003'
      WHEN D.[分類コード]=3  THEN '4005'
      WHEN D.[分類コード]=4  THEN '4007'
      ELSE '4009'
    END                             AS [項目コード],
    D.[店番]                          AS [店番],
    D.[ＣＩＦ番号]                    AS [ＣＩＦ番号],
    D.[件数]                          AS [件数],
    0                               AS [金額]
FROM
    (
     SELECT
         C.[作成基準日]               AS [作成基準日],
         C.[店番]                     AS [店番],
         C.[ＣＩＦ番号]               AS [ＣＩＦ番号],
         C.[分類コード]               AS [分類コード],
         SUM(C.[件数])                AS [件数]
     FROM
         (
          SELECT
              A.[作成基準日]               AS [作成基準日],
              A.[店番]                     AS [店番],
              A.[ＣＩＦ番号]               AS [ＣＩＦ番号],
              A.[件数]                     AS [件数],
              ISNULL(B.[分類コード],9)     AS [分類コード]
          FROM
              (
               SELECT
                   [前月末日]              AS [作成基準日],
                   [TBN]                   AS [店番],
                   [CFB]                   AS [ＣＩＦ番号],
                   CASE WHEN [BCYTRKUWKFF8]='3'
                     THEN 1
                     ELSE -1
                   END                   AS [件数],
                   [ITSCOD00C]             AS [委託者コードＣ]
               FROM  ${DB_T_SRC}.T_YK50010D_SRC001                   /* 流動性入払 */
               CROSS JOIN  ${INFO_DB}.T_KT00060D_LOAD                /* 日付テーブル */
               WHERE ([TAKKNB] BETWEEN [前月月初日] AND [前月末日])     /*前月分*/
                 AND [ERRHYJ]=''                                    /*エラー表示*/
                 AND [BCYTRKUWKFF8] IN ('3', '4')                   /*バッチ用取引内訳Ｆ８(入出金区分) */ 
                 AND [TKYCOD] ='700'                                /*摘要コード*/
              ) AS A
              LEFT JOIN  ${INFO_DB}.T_CG0003E AS B                   /* クレジット会社情報 */
                ON SUBSTRING(A.[委託者コードＣ],1,3) = B.[委託者コード＿種目]
               AND SUBSTRING(A.[委託者コードＣ],4,3) = B.[委託者コード＿内訳]
          ) AS C
          GROUP BY C.[作成基準日],C.[店番],C.[ＣＩＦ番号],C.[分類コード]
    ) AS  D;
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
