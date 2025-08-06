#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :顧客商品契約有無情報                      | T_SN25000D_OBJ
# フェーズ          :当行投信（一般預り・特定預り）作成
# サイクル          :日次
# 参照テーブル      :【BestWay】投信口座残高属性               | T_OM01020D_SEM001
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024-01-25        :新規作成                                  | KODAMA
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
/*       当行投信（一般預り・特定預り）                                */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_SN25000D_OBJ
SELECT
  (SELECT [前日] FROM ${INFO_DB}.T_KT00060D_LOAD ) AS [作成基準日],
  A.[HOSTBN]           AS [店番],
  A.[HOSCFB]           AS [ＣＩＦ番号],
  CASE
   WHEN A.[TokuAzuKbn] = ''  THEN '3300100000000'
   WHEN A.[TokuAzuKbn] = '1' THEN '3300200000000'
   ELSE '' END        AS [商品コード]
FROM ${DB_T_SEM}.T_OM01020D_SEM001 AS A
CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD AS B
WHERE ( SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD )
      BETWEEN A.[Start_Date] AND A.[End_Date] AND A.[Record_Deleted_Flag] = 0
AND   A.[TokuAzuKbn] IN ('','1')
AND   A.[YakZan] > 0
GROUP BY [作成基準日], [店番], [ＣＩＦ番号], [商品コード];
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
