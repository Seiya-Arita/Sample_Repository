#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :外貨事業資金月中積数                      | HN_INFO.T_NY03610D_OBJ
# フェーズ          :名寄せ代表選定情報
# サイクル          :日次
# 参照テーブル      :GDKA異動明細（残高）                      | HN_V_SRC.T_GK50020D_SRC001
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
/* 外貨事業資金月中積数 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_NY03610D_OBJ]
SELECT [データ基準日],
       [取次店番],
       [国内取引先番号],
       [科目コード内部],
       [通貨コード],
       [取組番号],
       [復活番号],
       [外為店番],
       SUM(CAST([残高] AS DECIMAL(19))) AS [月中積数]
FROM (
    SELECT [前前日] AS [データ基準日],
           [基準日],
           [取次店番],
           [国内取引先番号],
           [科目コード内部],
           [通貨コード],
           [取組番号],
           [復活番号],
           [外為店番],
           [残高]
    FROM (
        SELECT [MAKKJB] AS [作成基準日],
               [TTGTBN] AS [取次店番],
               [KNDTRSBNG] AS [国内取引先番号],
               [KCDNIB] AS [科目コード内部],
               [TWCCOD] AS [通貨コード],
               [TR5] AS [取組番号],
               [FKTBNG] AS [復活番号],
               [GTMTBN] AS [外為店番],
               [EQAZAN] AS [残高]
        FROM ${DB_T_SRC}.[T_GK50020D_SRC001]
        WHERE [KCDNIB] IN ('1300','1309','1310','1319')
          AND [EQAZAN] > 0
    ) AS A
    INNER JOIN
    /* 月初日から前前日までの日付を取得 */
    (
        SELECT T3.[前前日], T4.[基準日]
        FROM (
            /* 前日を基準にして月初日を取得する */
            SELECT T1.[前前日], T2.[当月月初日]
            FROM ${INFO_DB}.[T_KT00060D_LOAD] AS T1
            INNER JOIN ${INFO_DB}.[T_KT00080D_LOAD] AS T2
                ON T1.[前前日] = T2.[基準日]
        ) AS T3
        CROSS JOIN ${INFO_DB}.[T_KT00080D_LOAD] AS T4
        WHERE T4.[基準日] BETWEEN T3.[当月月初日] AND T3.[前前日]
    ) AS B
    ON A.[作成基準日] = B.[基準日]
) AS C
GROUP BY [データ基準日], [取次店番], [国内取引先番号], [科目コード内部], [通貨コード], [取組番号], [復活番号], [外為店番];
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
