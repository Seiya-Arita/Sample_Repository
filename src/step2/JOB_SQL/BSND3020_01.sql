#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :顧客商品契約有無＿階層４                | HN_INFO.T_SN30200D_WK1
# フェーズ          :階層４作成
# サイクル          :日次
# 参照テーブル      :業務支援系商品取引有無情報              | HN_V_SRC.T_SN30100D_SRC001
#                   :日付テーブル                            | HN_INFO.T_KT00060D_LOAD
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2023-09-19        :新規作成                                | Kodama
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
/* 業務支援系商品マスタで管理している全ての階層の取引有無情報を作成する */
/* このＳＱＬでは、そのうち階層４の商品コードを作成する                */
/* ****************************************************************** */

/* 階層４で突合 */
INSERT INTO ${INFO_DB}.T_SN30200D_WK1
SELECT
   0          AS [作成基準日]
  ,[TBN]      AS [店番]
  ,[CFB]      AS [ＣＩＦ番号]
  ,[TWGCFB]   AS [統合ＣＩＦ番号]
  ,[SFM]      AS [商品コード]
FROM ${DB_T_SRC}.T_SN30100D_SRC001
WHERE (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD)
BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0;
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
