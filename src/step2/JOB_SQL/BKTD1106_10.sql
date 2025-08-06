#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :預金計数ワーク  円貨流動性預金            | HN_INFO.T_KT11070D_WK10
# フェーズ          :ＣＩＦ残高
# サイクル          :日次
# 参照テーブル      :預金計数ワーク                            | HN_INFO.T_KT11070D_WKnn
#
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
/* 預金計数ワーク 円貨流動性預金                                      */
/* 当座＋普通＋通知＋別段＋納税準備＋貯蓄                             */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT11070D_WK10
SELECT
    MAX(ZN.[作成基準日])              AS [作成基準日],
    ZN.[店番]                         AS [店番],
    ZN.[ＣＩＦ番号]                   AS [ＣＩＦ番号],
    ''                                AS [科目],
    'ENKARYUDOYOKN'                   AS [商品コード],
    SUM(ZN.[残高])                    AS [残高],
    SUM(ZN.[月中積数])                AS [月中積数],
    SUM(ZN.[月中平残])                AS [月中平残],
    SUM(ZN.[期中積数])                AS [期中積数],
    SUM(ZN.[期中平残])                AS [期中平残]
FROM
(
    SELECT * FROM ${INFO_DB}.T_KT11070D_WK01 UNION ALL
    SELECT * FROM ${INFO_DB}.T_KT11070D_WK02 UNION ALL
    SELECT * FROM ${INFO_DB}.T_KT11070D_WK03 UNION ALL
    SELECT * FROM ${INFO_DB}.T_KT11070D_WK04 UNION ALL
    SELECT * FROM ${INFO_DB}.T_KT11070D_WK05 UNION ALL
    SELECT * FROM ${INFO_DB}.T_KT11070D_WK06
) AS ZN
GROUP BY ZN.[店番], ZN.[ＣＩＦ番号];
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
