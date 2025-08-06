#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :預かり資産残高＿一時払保険                | HN_INFO.T_NY03002D_WK5
# フェーズ          :預かり資産残高
# サイクル          :日次
# 参照テーブル      :保険契約明細情報                          | HN_V_SRC.T_SN05570D_SRC001
#                   :保険商品別通貨利率                        | HN_V_SEM.T_SN12400D_SEM001
#                   :日付テーブル                              | HN_INFO.T_KT00060D_LOAD
# ------------------------------------------------------------------------------
# 2023-02-07        :新規作成                                  | Nagata
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
/* 保険契約明細情報（一時払） */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_NY03002D_WK5]
SELECT
   A.[作成基準日]                           AS [作成基準日],
   A.[ＣＩＦ店番]                           AS [店番],
   A.[ＣＩＦ契約番号]                       AS [ＣＩＦ番号],
   ''                                       AS [科目],
   A.[通番]                                 AS [口座番号],
   A.[基本保険金額] * COALESCE(B.[レート],1) AS [残高]
FROM
    (
      SELECT T2.[前日]                      AS [作成基準日],
            T1.[CIFTBN]                    AS [ＣＩＦ店番],
            T1.[CIFKYABNG]                 AS [ＣＩＦ契約番号],
            T1.[NUB]                       AS [通番],
            T1.[SHNZOKCOD]                 AS [商品属性コード],
            T1.[KFNHODTMYSRI]              AS [基本保険金通貨種類],
            T1.[KFNHENPRI]                 AS [基本保険金額]
      FROM       ${DB_T_SRC}.[T_SN05570D_SRC001]  AS T1
      CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD]     AS T2
      WHERE CAST(CAST(T2.[前前日] AS CHAR(8)) AS DATE) BETWEEN T1.[Start_Date] AND T1.[End_Date] AND
            T1.[Record_Deleted_Flag]=0               AND
            T1.[DTASRI] NOT IN ('2','3')             AND   /* データ種類 */
            T1.[SNESEESHNKBN]='01'                   AND   /* 資産性商品区分 */
            COALESCE(CAST(T1.[CIFKYABNG] AS NUMERIC),0)<>0 AND   /* ＣＩＦ契約番号 */
            T1.[KFNHENPRI]>0                               /* 基本保険金額 */
    ) AS A
LEFT JOIN
    (
      SELECT T1.[SHNZOKCOD]                 AS [商品属性コード],
            T1.[HENTWCCOD]                 AS [保険通貨コード],
            T1.[RAT]                       AS [レート]
      FROM       ${DB_T_SEM}.[T_SN12400D_SEM001] AS T1
      CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD]    AS T2
      WHERE CAST(CAST(T2.[前前日] AS CHAR(8)) AS DATE) BETWEEN T1.[Start_Date] AND T1.[End_Date] AND
            T1.[Record_Deleted_Flag]=0
    ) AS B
ON A.[商品属性コード]=B.[商品属性コード] AND A.[基本保険金通貨種類]=B.[保険通貨コード];
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
