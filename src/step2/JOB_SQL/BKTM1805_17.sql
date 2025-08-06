#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :ＣＩＦ動態情報縦持ち（SCOPE）  | T_KT18050D_OBJ
#                      ＢＣカード自振額算出（項目コード：3009）
# フェーズ          :テーブル作成
# サイクル          :月次
# 参照テーブル      :流動性入払                     | T_YK50010D_SRC001
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
INSERT INTO ${INFO_DB}.T_KT18050M_OBJ
SELECT
     [作成基準日]                AS [作成基準日],
    '3009'                    AS [項目コード],
    C.[店番]                    AS [店番],
    C.[ＣＩＦ番号]              AS [ＣＩＦ番号],
    0                         AS [件数],
    SUM(C.[金額])               AS [金額]
FROM (
    SELECT
         B.[前月末日]            AS [作成基準日],
        A.[TBN]                 AS [店番],
        A.[CFB]                 AS [ＣＩＦ番号],
        CASE WHEN A.[BCYTRKUWKFF8]='3'
           THEN A.[TRKKGK]
           ELSE A.[TRKKGK] * -1
         END                   AS [金額]
    FROM  ${DB_T_SRC}.T_YK50010D_SRC001  AS A                    /* 流動性入払 */
    CROSS JOIN  ${INFO_DB}.T_KT00060D_LOAD  AS B                 /* 日付テーブル */
        WHERE (A.[TAKKNB] BETWEEN B.[前月月初日] AND B.[前月末日])     /*前月分*/
          AND  A.[ERRHYJ]=''                                       /*エラー表示*/
          AND  A.[BCYTRKUWKFF8] IN ('3','4')                       /*バッチ用取引内訳Ｆ８(入出金区分) 支払・支払訂正*/
          AND ((A.[TKYCOD] BETWEEN '570' AND '574')
           OR  (A.[TKYCOD]='577'))                                 /*摘要コード*/
          AND  A.[BMPCOD] <> ''                                    /*ＢＭＰコード*/
    ) AS C
GROUP BY C.[作成基準日],C.[店番],C.[ＣＩＦ番号];
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
