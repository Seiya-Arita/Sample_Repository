#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :保険商品別通貨利率展開                    | HN_INFO.T_KT13160D_OBJ
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :保険商品別通貨利率                        | HN_V_SEM.T_SN12400D_SEM001
#                    基準日累積テーブル                        | HN_INFO.T_KT90080D_OBJ
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
/* 保険商品別通貨利率展開 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT13160D_OBJ]
SELECT
    B.[基準日] AS [作成基準日],
    A.[SHNZOKCOD] AS [商品属性コード],
    A.[HENTWCCOD] AS [保険通貨コード],
    A.[RAT] AS [レート]
FROM
    (SELECT
        [start_date],
        [end_date],
        [SHNZOKCOD],
        [HENTWCCOD],
        [RAT]
     FROM ${DB_T_SEM}.[T_SN12400D_SEM001]
     WHERE [Record_Deleted_Flag] = 0
       AND [end_date] >= (SELECT CAST(CAST([期初日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT90085D_OBJ])
    ) AS A
    INNER JOIN
    (
        SELECT CAST(CAST([基準日] AS CHAR(8)) AS DATE) AS [基準日ＤＴ], [基準日]
        FROM ${INFO_DB}.[T_KT90080D_OBJ]
        WHERE [基準日] >= (SELECT [期初日] FROM ${INFO_DB}.[T_KT90085D_OBJ])
          AND [基準日] <= (SELECT [基準日] FROM ${INFO_DB}.[T_KT90085D_OBJ])
    ) AS B
    ON B.[基準日ＤＴ] BETWEEN A.[start_date] AND A.[end_date];
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
