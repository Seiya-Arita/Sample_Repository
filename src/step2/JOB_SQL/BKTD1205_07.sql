#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :流動性基本情報を取得                      | HN_INFO.T_KT12050D_WK
# フェーズ          :ＣＩＦ残高
# サイクル          :日次
# 参照テーブル      :流動性基本情報断面展開                    | HN_INFO.T_KT10110D_OBJ
#                    預金ＣＩＦ基本S断面展開                   | HN_INFO.T_KT10100D_OBJ
#                    基準日テーブル                            | HN_INFO.T_KT90085D_OBJ
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
/* 流動性基本情報集計 作成 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT12050D_WK]
SELECT
   TA.[作成基準日]      AS [作成基準日],
   TA.[TBN]             AS [店番],
   TA.[CFB]             AS [ＣＩＦ番号],
   TA.[KMK]             AS [科目],
   TA.[KZB]             AS [取扱番号],
   ''                   AS [取組番号],
   ''                   AS [通貨コード],
   ''                   AS [復活番号],
   0                    AS [外為店番],
   TB.[HJKCOD]          AS [法個人コード],
   TB.[GYSCOD]          AS [業種コード],
   0                    AS [稟議一連番号],
   0                    AS [稟議協議書番号],
   TA.[CDLCOD]          AS [カードローンコード],
   TA.[SBTCOD]          AS [種別コード＿預金],
   ''                   AS [完済区分],
   ''                   AS [制度融資コード],
   ''                   AS [付保証コード],
   ''                   AS [枠コード],
   ''                   AS [期間コード],
   ''                   AS [商品コード１],
   ''                   AS [商品コード２],
   ''                   AS [商品コード３],
   ''                   AS [商品コード４],
   ''                   AS [商品コード５],
   ''                   AS [商品コード６],
   TA.[RDSSJW]          AS [ＷＥＢ口座区分],
   TA.[TGYKNJMCZ]*-1    AS [残高],
   0                    AS [保証金額],
   TA.[KZTBEE]          AS [口座開設日],
   '7'                  AS [作成ＳＱＬ番号]
FROM
/*流動性基本・期中全断面を抽出*/
(
    SELECT
        [作成基準日],
        [TBN],
        [CFB],
        [KMK],
        [KZB],
        [CDLCOD],
        [SBTCOD],
        [RDSSJW],
        [TGYKNJMCZ],
        [KZTBEE]
    FROM ${INFO_DB}.[T_KT10110D_OBJ]
    WHERE [KMK] IN ('11','12') AND [SSSHYJ]=''
      AND [TGYKNJMCZ]<0
      AND [SSSHYJ]=''
) AS TA
INNER JOIN
(
    SELECT [作成基準日],[TBN],[CFB],[HJKCOD],[GYSCOD]
    FROM ${INFO_DB}.[T_KT10100D_OBJ] WHERE [SSSHYJ]=''
) AS TB
    ON TA.[作成基準日] = TB.[作成基準日]
   AND TA.[TBN] = TB.[TBN]
   AND TA.[CFB] = TB.[CFB];
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
