#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :預金計数ワーク 科目21(一般定期)           | HN_INFO.T_KT11070D_WK16
# フェーズ          :ＣＩＦ残高
# サイクル          :日次
# 参照テーブル      :定期預入明細展開                          | HN_INFO.T_KT10140D_OBJ
#                    基準日テーブル                            | HN_INFO.T_KT90085D_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/07/08 新規作成                                          | TSUKINOKI
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
/* 預金計数ワーク 科目21(財形預金　住宅財形) */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT11070D_WK16
SELECT
     MAX([基準日])       AS [作成基準日]
    ,A.[店番]            AS [店番]
    ,A.[ＣＩＦ番号]      AS [ＣＩＦ番号]
    ,A.[科目]            AS [科目]
    ,'2030300000000'     AS [商品コード]
    ,SUM(CASE WHEN A.[作成基準日]=[基準日]      THEN A.[残高] ELSE 0 END)                       AS [残高]
    ,SUM(CASE WHEN A.[作成基準日]>=[当月月初日] THEN A.[残高] ELSE 0 END)                       AS [月中積数]
    ,SUM(CASE WHEN A.[作成基準日]>=[当月月初日] THEN A.[残高] ELSE 0 END)/MAX([基準日月中日数]) AS [月中平残]
    ,SUM(CASE WHEN A.[作成基準日]>=[期初日]     THEN A.[残高] ELSE 0 END)                       AS [期中積数]
    ,SUM(CASE WHEN A.[作成基準日]>=[期初日]     THEN A.[残高] ELSE 0 END)/MAX([基準日期中日数]) AS [期中平残]
FROM
    (SELECT
       [作成基準日]
      ,[TBN]       AS [店番]
      ,[CFB]       AS [ＣＩＦ番号]
      ,[KMK]       AS [科目]
      ,[YNUKGK]    AS [残高]
     FROM ${INFO_DB}.T_KT10140D_OBJ
     WHERE
           [KMK] IN ('21')
       AND [SSSHYJ]=''
       AND [KFNSFM]='82'
       AND [TIKKBN]<>'91'
       AND [作成基準日]>=(SELECT [期初日] FROM ${INFO_DB}.T_KT90085D_OBJ)
       AND [作成基準日]<=(SELECT [基準日] FROM ${INFO_DB}.T_KT90085D_OBJ)
    ) AS A
    INNER JOIN
    (/*基準日時点で生きてるCIFのみ*/
     SELECT [TBN],[CFB] FROM ${INFO_DB}.T_KT10100D_OBJ
     WHERE [作成基準日]=(SELECT [基準日] FROM ${INFO_DB}.T_KT90085D_OBJ) AND [SSSHYJ]=''
    ) AS B
    ON  A.[店番]=B.[TBN]
    AND A.[ＣＩＦ番号]=B.[CFB]
    CROSS JOIN ${INFO_DB}.T_KT90085D_OBJ
GROUP BY  [店番],[ＣＩＦ番号],[科目];
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
