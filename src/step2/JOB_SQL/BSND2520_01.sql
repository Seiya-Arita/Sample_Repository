#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【顧客商品有無】信託業務(X-NET)           | T_SN25200D_WK1
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :遺言信託情報累積                          | T_SN02700D_SRC001
#                   :日付テーブル                              | HN_INFO.T_KT00060D_LOAD
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024-02-06        :新規作成                                  | KOZAKI
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
/* 【顧客商品有無】信託業務(X-NET) 遺言信託情報 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_SN25200D_WK1
SELECT
   (SELECT [前日] FROM ${INFO_DB}.T_KT00060D_LOAD) AS [作成基準日],
   Z.[店番] AS [店番],
   Z.[ＣＩＦ番号] AS [ＣＩＦ番号],
   Z.[商品コード] AS [商品コード]
FROM
(
/* 遺言信託 */
    SELECT
      [TBN] AS [店番],
      [CFB] AS [ＣＩＦ番号],
      '3070000000000' AS [商品コード]
    FROM ${DB_T_SRC}.T_SN02700D_SRC001
    WHERE (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD)
          BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
          AND [TBN] <> 0
          AND [CFB] <> 0
    GROUP BY [TBN], [CFB]
) AS Z;
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
