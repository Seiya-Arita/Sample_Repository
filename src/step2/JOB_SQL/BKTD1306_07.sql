#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :預り資産計数集約(信託財産)                | HN_INFO.T_KT13070D_WK07
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :信託財産断面展開                          | HN_INFO.T_KT13180D_OBJ
#                    ＣＩＦ残高基準日テーブル                  | HN_INFO.T_KT90085D_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/10/22 新規作成                                          | H.Okura
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
/* 預り資産計数ワーク (信託財産) */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT13070D_WK07
SELECT
     MAX([基準日])       AS [作成基準日]
    ,A.[店番]            AS [店番]
    ,A.[ＣＩＦ番号]      AS [ＣＩＦ番号]
    ,'3060000000000'     AS [商品コード]
    ,SUM(CASE WHEN A.[作成基準日]=[基準日]      THEN A.[残高] ELSE 0 END)                       AS [残高]
    ,SUM(CASE WHEN A.[作成基準日]>=[当月月初日] THEN A.[残高] ELSE 0 END)                       AS [月中積数]
    ,SUM(CASE WHEN A.[作成基準日]>=[当月月初日] THEN A.[残高] ELSE 0 END)/MAX([基準日月中日数]) AS [月中平残]
    ,SUM(CASE WHEN A.[作成基準日]>=[期初日]     THEN A.[残高] ELSE 0 END)                       AS [期中積数]
    ,SUM(CASE WHEN A.[作成基準日]>=[期初日]     THEN A.[残高] ELSE 0 END)/MAX([基準日期中日数]) AS [期中平残]
FROM
   (SELECT
      [作成基準日]
     ,[店番]              AS [店番]
     ,[ＣＩＦ番号]        AS [ＣＩＦ番号]
     ,[基準日＿信託元本]  AS [残高]
    FROM ${INFO_DB}.T_KT13180D_OBJ
    WHERE ([受益権階層コード] = '1' OR ([受益権階層コード] = '2' AND [基準日＿信託元本] > 0))
      AND [作成基準日]>=(SELECT [期初日] FROM ${INFO_DB}.T_KT90085D_OBJ)
      AND [作成基準日]<=(SELECT [基準日] FROM ${INFO_DB}.T_KT90085D_OBJ)
    ) AS A
    INNER JOIN
    (/*基準日時点で生きてるCIFのみ*/
     SELECT [TBN] AS [店番],[CFB] AS [ＣＩＦ番号],[SSSHYJ] AS [生死表示] FROM ${INFO_DB}.T_KT10100D_OBJ
     WHERE  [作成基準日]=(SELECT [基準日] FROM ${INFO_DB}.T_KT90085D_OBJ) AND [生死表示]=''
    ) AS B
    ON  A.[店番]=B.[店番]
    AND A.[ＣＩＦ番号]=B.[ＣＩＦ番号]
    CROSS JOIN ${INFO_DB}.T_KT90085D_OBJ
GROUP BY  A.[店番],A.[ＣＩＦ番号]
;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ######################################################################### */
/*                      通常の退出処理                              */
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
