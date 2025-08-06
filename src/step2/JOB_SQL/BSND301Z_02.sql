#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :顧客商品契約有無情報                      | T_SN30100D_OBJ
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :顧客商品契約有無情報_中間ワーク           | T_SN30102D_OBJ
#                   :CDKA同一人名寄せ                          | T_MA00030M_SRC001
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
/* 顧客商品契約有無情報 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_SN30100D_OBJ]
SELECT
   A.[作成基準日]
  ,A.[店番]
  ,A.[ＣＩＦ番号]
  ,B.[統合ＣＩＦ番号]
  ,A.[商品コード]
FROM ${INFO_DB}.[T_SN30102D_OBJ] AS A
INNER JOIN
  ( SELECT
       [Brnch_Cd]    AS [店番]
      ,[Cif_No]      AS [ＣＩＦ番号]
      ,[Intg_Cif_No] AS [統合ＣＩＦ番号]
    FROM ${DB_T_SRC}.[T_MA00030M_SRC001]
    WHERE ( SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE)
            FROM   ${INFO_DB}.[T_KT00060D_LOAD] )
    BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
  ) AS B
ON  A.[店番]       = B.[店番]
AND A.[ＣＩＦ番号] = B.[ＣＩＦ番号]
;
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
