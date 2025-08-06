#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :債券商品コード採番ワーク                  | T_KT41010D_WK10
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :BRKA債権銘柄基本S                         | T_SF50040D_SRC001
#
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2021-08-30        :新規作成                                  | SVC TSUKINOKI
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
/* BRKA債券銘柄基本S                                              */
/* 仕組債取得・自動採番                                           */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT41010D_WK10
SELECT
    DTE.[前日],
    '9' AS [コード階層区分１],
    '資産運用' AS [コード階層名称１],
    '01' AS [コード階層区分２],
    '公共債' AS [コード階層名称２],
    '01' AS [コード階層区分３],
    '公共債' AS [コード階層名称３],
    PRT.[銘柄コード] AS [コード階層区分４],
    PRT.[漢字銘柄名] AS [コード階層名称４],
    '9' + '01' + '01' + PRT.[銘柄コード] AS [商品コード],
    PRT.[漢字銘柄名] AS [商品名称],
    ROW_NUMBER() OVER (PARTITION BY [銘柄コード] ORDER BY [漢字銘柄名]) AS [連番]
FROM
(
   SELECT
      SUBSTRING([MGRCOD],1,8) AS [銘柄コード],
      RTRIM([NCRMGRMEL],'　') AS [漢字銘柄名]
   FROM ${DB_T_SRC}.T_SF50040D_SRC001
   WHERE (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD)
         BETWEEN [Start_Date] AND [End_Date]
     AND [MGRCOD] <> '111111111111'
   GROUP BY [MGRCOD], [NCRMGRMEL]
) AS PRT
CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD AS DTE;
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
