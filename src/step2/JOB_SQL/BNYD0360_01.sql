#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :流動性事業資金月中積数                    | HN_INFO.T_NY03600D_OBJ
# フェーズ          :名寄せ代表選定情報
# サイクル          :日次
# 参照テーブル      :YRKA流動性基本S                           | HN_V_SRC.T_YK51010D_SRC001
#                   :日付テーブル                              | HN_INFO.T_KT00060D_LOAD
#                   :日付累積テーブル                          | HN_INFO.T_KT00080D_LOAD
# ------------------------------------------------------------------------------
# 2023-02-27        :新規作成                                  | Nagata
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
/* 流動性事業資金月中積数 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_NY03600D_OBJ]
SELECT [データ基準日], [店番], [ＣＩＦ番号], [科目], [口座番号], SUM([残高]) AS [月中積数]
FROM (
    SELECT [前前日] AS [データ基準日], [基準日], [開始日], [終了日], [店番], [ＣＩＦ番号], [科目], [口座番号], [残高]
    FROM (
        SELECT [Start_Date] AS [開始日], [End_Date] AS [終了日], [TBN] AS [店番], [CFB] AS [ＣＩＦ番号], [KMK] AS [科目], [KZB] AS [口座番号], [TGYKNJMCZ] * (-1) AS [残高]
        FROM ${DB_T_SRC}.[T_YK51010D_SRC001]
        WHERE [Record_Deleted_Flag] = 0 AND [TGYKNJMCZ] < 0 AND [SSSHYJ] = '' AND [KMK] IN ('11','12')
    ) AS A
    INNER JOIN
    /* 月初日から前前日までの日付を取得 */
    (
        SELECT T3.[前前日], T4.[基準日]
        FROM (
            /* 前前日を基準にして月初日を取得 */
            SELECT T1.[前前日], T2.[当月月初日] AS [月初日]
            FROM ${INFO_DB}.[T_KT00060D_LOAD] AS T1
            INNER JOIN ${INFO_DB}.[T_KT00080D_LOAD] AS T2
            ON T1.[前前日] = T2.[基準日]
        ) AS T3
        CROSS JOIN ${INFO_DB}.[T_KT00080D_LOAD] AS T4
        WHERE T4.[基準日] BETWEEN T3.[月初日] AND T3.[前前日]
    ) AS B
    ON B.[基準日] BETWEEN CAST(A.[開始日] AS INT) + 19000000 AND CAST(A.[終了日] AS INT) + 19000000
) AS C
GROUP BY [データ基準日], [店番], [ＣＩＦ番号], [科目], [口座番号];
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
