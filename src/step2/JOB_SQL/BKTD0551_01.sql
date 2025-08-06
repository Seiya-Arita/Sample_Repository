#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【管理店】手動設定管理店情報              | HN_INFO.T_KT05510D_OBJ
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :【管理店】手動設定情報                    | HN_INFO.T_KT05500Z_OBJ
#                   :【管理店】管理店名寄せ情報                | HN_INFO.T_KT05580D_OBJ
#                   :店属性                                    | HN_V_SRC.T_SN09100D_SRC001
#                   :日付テーブル                              | HN_INFO.T_KT00080D_LOAD
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/09/30 新規作成                                          | M.Shunya
# 2025/01/31 法人を名寄せしない                                | M.Shunya
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
/* 【管理店】手動設定管理店情報 作成、抽出 */
/* ****************************************************************** */
WITH data AS
(
      SELECT
            A.[登録日],
            A.[店番],
            A.[ＣＩＦ番号],
            A.[管理店番],
            ROW_NUMBER() OVER (PARTITION BY B.[統合番号] ORDER BY A.[登録日] DESC, A.[店番], A.[ＣＩＦ番号], A.[管理店番] DESC) AS row_num
      FROM ${INFO_DB}.[T_KT05500Z_OBJ]
      WHERE [登録日] <= (SELECT [基準日] FROM ${INFO_DB}.[T_KT00060D_LOAD])
      ) AS A
      INNER JOIN ${INFO_DB}.[T_KT05580D_OBJ] AS B
      ON (A.[店番] = B.[店番]
      AND A.[ＣＩＦ番号] = B.[ＣＩＦ番号])
)


INSERT INTO ${INFO_DB}.[T_KT05510D_OBJ]
SELECT
      B.[統合番号],
      A.[店番],
      A.[ＣＩＦ番号],
      A.[管理店番],
      '01'         AS [管理店番チャネル区分]
FROM data AS A
      INNER JOIN ${INFO_DB}.[T_KT05580D_OBJ] AS B
      ON (A.[店番] = B.[店番]
      AND A.[ＣＩＦ番号] = B.[ＣＩＦ番号])
INNER JOIN (
      SELECT
            CAST([TBN] AS DECIMAL(3))   AS [店番]
      FROM ${DB_T_SRC}.[T_SN09100D_SRC001]
      WHERE [MAKKJB] = (SELECT [基準日] FROM ${INFO_DB}.[T_KT00060D_LOAD])
      AND  [TBN] <> ''
      AND ([HSB] = ''
            OR (CAST(SUBSTRING([HSB],1,10) AS DECIMAL(8))) > (SELECT [基準日] FROM ${INFO_DB}.[T_KT00060D_LOAD]))
      GROUP BY [TBN]
      ) AS C
      ON (A.[管理店番] = C.[店番])
WHERE A.[row_num] = 1;
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
