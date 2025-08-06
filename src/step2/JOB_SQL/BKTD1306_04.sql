#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :預り資産計数集約(九州ＦＧ証券投信)        | HN_INFO.T_KT13070D_WK04
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :九州ＦＧ証券投信                          | HN_V_SRC.T_SK51040D_SRC001
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
/* 預り資産計数ワーク (九州ＦＧ証券投信) */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT13070D_WK04
SELECT
     MAX([基準日])       AS [作成基準日]
    ,A.[店番]            AS [店番]
    ,A.[ＣＩＦ番号]      AS [ＣＩＦ番号]
    ,'3100000000000'     AS [商品コード]
    /* ＦＧ直近データは前日となる */
    ,SUM(CASE WHEN A.[作成基準日]=[前日]        THEN A.[残高] ELSE 0 END)                      AS [残高]
    ,SUM(CASE WHEN A.[作成基準日]>=[当月月初日] THEN A.[残高] ELSE 0 END)                      AS [月中積数]
    ,SUM(CASE WHEN A.[作成基準日]>=[当月月初日] THEN A.[残高] ELSE 0 END)/MAX([基準日月中日数])AS [月中平残]
    ,SUM(CASE WHEN A.[作成基準日]>=[期初日]     THEN A.[残高] ELSE 0 END)                      AS [期中積数]
    ,SUM(CASE WHEN A.[作成基準日]>=[期初日]     THEN A.[残高] ELSE 0 END)/MAX([基準日期中日数])AS [期中平残]
FROM
   (SELECT
      [MAKKJB]           AS [作成基準日]
     ,[HOSTBN]           AS [店番]
     ,[HOSCFB]           AS [ＣＩＦ番号]
     ,[JQAHYGGOK]        AS [残高]
    FROM ${DB_T_SRC}.T_SK51040D_SRC001
    WHERE [JQAHYGGOK] > 0
      AND [MAKKJB]>=(SELECT [期初日] FROM ${INFO_DB}.T_KT90085D_OBJ)
      AND [MAKKJB]<=(SELECT [基準日] FROM ${INFO_DB}.T_KT90085D_OBJ)
    ) AS A
    INNER JOIN
    (/*基準日時点で生きてるCIFのみ*/
     SELECT [TBN] [店番],[CFB] [ＣＩＦ番号],[SSSHYJ] [生死表示] FROM ${INFO_DB}.T_KT10100D_OBJ
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
