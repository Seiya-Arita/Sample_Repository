#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :顧客商品契約有無情報                      | T_SN25100D_OBJ
# フェーズ          :KFG証券投信（NISA口座_口座開設）作成
# サイクル          :日次
# 参照テーブル      :九州FG証券顧客基本属性情報                | T_SK51110D_SRC001
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024-01-23        :新規作成                                  | KODAMA
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
/*       顧客商品有無情報作成（商品追加＿資産運用（取引ベース））        */
/*       KFG証券投信（NISA口座_口座開設）                              */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_SN25100D_OBJ
SELECT
  (SELECT [前日] FROM ${INFO_DB}.T_KT00060D_LOAD ) AS [作成基準日],
  [HOSTBN]           AS [店番],
  [HOSCFB]           AS [ＣＩＦ番号],
  '3120300000000'    AS [商品コード]
FROM ${DB_T_SRC}.T_SK51110D_SRC001
WHERE ( SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD )
      BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
AND   [N1SKYAKBN] = '契約'
GROUP BY (SELECT [前日] FROM ${INFO_DB}.T_KT00060D_LOAD ), [HOSTBN], [HOSCFB], [商品コード];
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
