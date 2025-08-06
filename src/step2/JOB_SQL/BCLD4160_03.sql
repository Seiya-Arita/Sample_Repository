#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :業務支援系商品マスタ_マージ（融資分）     | T_KT41000D_OBJ
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :業務支援系商品マスタロード                | T_KT41000D_LOAD
#                   :業務支援系商品マスタ                      | V_KT410000_SRC001
#                   :【業務支援系商品採番】融資                | T_KT41000D_WK30
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2023-05-18       :新規作成                                   | KODAMA
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
/*#############################################*/
/* 自動採番・新規コードを抽出                  */
/*#############################################*/
INSERT INTO ${INFO_DB}.[T_KT41000D_WK92]
SELECT
   PRT.[作成基準日]
  ,PRT.[コード階層区分１]
  ,PRT.[コード階層名称１]
  ,PRT.[コード階層区分２]
  ,PRT.[コード階層名称２]
  ,PRT.[コード階層区分３]
  ,PRT.[コード階層名称３]
  ,PRT.[コード階層区分４]
  ,PRT.[コード階層名称４]
  ,PRT.[商品コード]
  ,PRT.[商品名称]
  ,PRT.[システム使用区分１]
  ,PRT.[システム使用区分２]
  ,PRT.[システム使用区分３]
  ,PRT.[システム使用区分４]
  ,PRT.[システム使用区分５]
  ,PRT.[システム使用区分６]
  ,PRT.[システム使用区分７]
  ,PRT.[システム使用区分８]
  ,PRT.[システム使用区分９]
  ,PRT.[システム使用区分１０]
  ,PRT.[システム使用区分１１]
  ,PRT.[システム使用区分１２]
  ,PRT.[システム使用区分１３]
  ,PRT.[システム使用区分１４]
  ,PRT.[システム使用区分１５]
  ,'1'         AS [登録種別]
  ,DTE.[前日]    AS [登録日]
  ,DTE.[前日]    AS [更新日]
  ,PRT.[削除フラグ]
  ,PRT.[備考]
FROM ${INFO_DB}.[T_KT41000D_WK30]  AS PRT
LEFT JOIN
  ( SELECT
      [CODCAIKBN001] AS [コード階層区分１]
     ,[CODCAIKBN004] AS [コード階層区分４]
    FROM ${DB_T_SRC}.[T_KT41000D_SRC001]
    WHERE (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE)
           FROM   ${INFO_DB}.[T_KT00060D_LOAD])
    BETWEEN [Start_Date] and [End_Date] ) AS ZEN
ON  PRT.[コード階層区分１] = ZEN.[コード階層区分１]
AND PRT.[コード階層区分４] = ZEN.[コード階層区分４]
CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS DTE
WHERE ZEN.[コード階層区分４] IS NULL;
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
