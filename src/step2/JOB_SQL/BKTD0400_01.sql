#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :最新通話可否情報（ワークテーブル）        | T_KT43050D_WK1
# フェーズ          :最新通話可否情報抽出
# サイクル          :日次
# 参照テーブル      :【CC】交渉経緯                            | T_CC40100D_OBJ
#                   :日付テーブル                              | T_KT00060D_LOAD
# 変更履歴
# ------------------------------------------------------------------------------
# 2022-01-12        :新規作成                                  | eBP Kodama
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
/* 最新通話可否情報 作成 */
/* ****************************************************************** */

WITH grouped AS
(   SELECT [統合ＣＩＦ番号],
            TRIM(dbo.OTranslate2([通話先電話番号],'-','')) AS [電話番号],
            [会話日時], 
            MAX([相手コード])   AS [相手コード]
    FROM ${INFO_DB}.T_CC40100D_OBJ
    WHERE [相手コード] NOT IN ('23','25') AND
            LEN(TRIM(dbo.OTranslate2([通話先電話番号],'-',''))) BETWEEN 7 AND 11
    GROUP BY [統合ＣＩＦ番号], TRIM(dbo.OTranslate2([通話先電話番号],'-','')), [会話日時] ),

Ranked AS (
    SELECT 
        T2.[前日]                     AS [作成基準日],
        T1.[統合ＣＩＦ番号]           AS [統合ＣＩＦ番号],
        T1.[電話番号]                 AS [電話番号],
        CASE
        WHEN T1.[相手コード] NOT IN ('22', '24') THEN '1'
        ELSE '' END                 AS [通話実績有無],
        CASE
        WHEN T1.[相手コード] NOT IN ('22', '24') AND
             T1.[会話日時] <> '' THEN
             CAST(SUBSTRING(T1.[会話日時],1,8) AS DECIMAL(8,0))
        ELSE 0 END                  AS [最終通話日],
        CASE
        WHEN T1.[相手コード] IN ('22','24') THEN '1'
        ELSE '' END                 AS [生死フラグ],
        T2.[前日]                     AS [更新日],
        RANK() OVER(PARTITION BY T1.[統合ＣＩＦ番号], T1.[電話番号] ORDER BY T1.[会話日時] DESC ) AS RNK
    FROM grouped AS T1
    CROSS JOIN
    ${INFO_DB}.T_KT00060D_LOAD   AS T2
)

INSERT INTO ${INFO_DB}.T_KT43050D_WK1
SELECT
    [作成基準日],
    [統合ＣＩＦ番号],
    [電話番号],
    [通話実績有無],
    [最終通話日],
    [生死フラグ],
    [更新日]
FROM  Ranked 
WHERE
   RNK = 1;
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
