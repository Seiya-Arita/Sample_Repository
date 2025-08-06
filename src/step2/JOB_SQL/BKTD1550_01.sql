#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :管理店情報マージＷＫ_バッチ               | HN_INFO.T_KT15501D_WK
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :【管理店】手動設定管理店情報_バッチ       | HN_INFO.T_KT15510D_OBJ
#                   :【管理店】変更依頼管理店情報_バッチ       | HN_INFO.T_KT15520D_OBJ
#                   :【管理店】取経先管理店情報_バッチ         | HN_INFO.T_KT15530D_OBJ
#                   :【管理店】貸出先管理店情報_バッチ         | HN_INFO.T_KT15540D_OBJ
#                   :【管理店】地区テリトリ管理店情報_バッチ   | HN_INFO.T_KT15550D_OBJ
#                   :【管理店】県外エリア管理店情報_バッチ     | HN_INFO.T_KT15560D_OBJ
#                   :【管理店】代表ＣＩＦ管理店情報_バッチ     | HN_INFO.T_KT15570D_OBJ
#                   :【管理店】優先順位マスタ(前日)            | HN_INFO.T_KT05501Z_001
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
/* 【管理店】管理店情報マージ */
/* ****************************************************************** */
WITH unionized AS 
(
      SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT15510D_OBJ]
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT15520D_OBJ]
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT15530D_OBJ]
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT15540D_OBJ]
   WHERE [管理店番]<>0
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT15550D_OBJ]
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT15560D_OBJ]
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT15570D_OBJ]
),

DATA AS 
(
      SELECT
         A.[統合番号],
         A.[管理店番],
         A.[管理店番チャネル区分],
         ROW_NUMBER() OVER (PARTITION BY A.[統合番号] ORDER BY B.[優先順位]) as row_num
      FROM unionized AS A
      INNER JOIN ${INFO_DB}.[T_KT05501Z_001] AS B
      ON (A.[管理店番チャネル区分] = B.[管理店番チャネル区分])
)

INSERT INTO ${INFO_DB}.[T_KT15501D_WK]
SELECT
      A.[統合番号],
      C.[店番],
      C.[ＣＩＦ番号],
      A.[管理店番],
      A.[管理店番チャネル区分],
      B.[優先順位]
FROM data AS A
INNER JOIN ${INFO_DB}.[T_KT05501Z_001] AS B
ON (A.[管理店番チャネル区分] = B.[管理店番チャネル区分])
INNER JOIN ${INFO_DB}.[T_KT15570D_OBJ] AS C
  ON (A.[統合番号] = C.[統合番号])
 AND (A.[管理店番チャネル区分] = C.[管理店番チャネル区分])
WHERE A.[row_num] = 1
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
SELECT @ExitCode AS ExitCode;
RETURN;
"


#
exit $?
