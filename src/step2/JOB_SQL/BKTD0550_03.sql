#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【管理店】管理店情報                      | HN_INFO.T_KT05500D_OBJ
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :【管理店】管理店情報ＷＫ                  | HN_INFO.T_KT05502D_WK
#                   :【管理店】管理店名寄せ情報                | HN_INFO.T_KT05580D_OBJ
#                   :【管理店】優先順位マスタ                  | HN_INFO.T_KT05501Z_OBJ
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
/* 【管理店】管理店情報 作成 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT05500D_OBJ]
SELECT
      A.[作成基準日],
      B.[統合ＣＩＦ番号],
      B.[店番],
      B.[ＣＩＦ番号],
      CASE WHEN B.[店番] < 101 OR B.[店番] > 400
           THEN B.[店番]
           ELSE A.[管理店番]
      END                     AS [管理店番],
      CASE WHEN B.[店番] < 101 OR B.[店番] > 400
           THEN (SELECT [管理店番チャネル区分] FROM ${INFO_DB}.[T_KT05501Z_OBJ]
                  WHERE [優先順位] = (SELECT MAX([優先順位]) FROM ${INFO_DB}.[T_KT05501Z_OBJ]))
           ELSE A.[管理店番チャネル区分]
      END                     AS [管理店番チャネル区分],
      CASE WHEN B.[店番] < 101 OR B.[店番] > 400
           THEN (SELECT MAX([優先順位]) FROM ${INFO_DB}.[T_KT05501Z_OBJ])
           ELSE A.[優先順位]
      END                     AS [優先順位],
      B.[代表ＣＩＦフラグ],
      A.[顧客区分コード],
      A.[住所コード],
      CASE WHEN B.[店番] < 101 OR B.[店番] > 400
           THEN 0
           ELSE A.[取経先他付与フラグ]
      END                     AS [取経先他付与フラグ],
      CASE WHEN B.[店番] < 101 OR B.[店番] > 400
           THEN 0
           ELSE A.[ミニブロック店番]
      END                     AS [ミニブロック店番],
      CASE WHEN B.[店番] < 101 OR B.[店番] > 400
           THEN B.[店番]
           ELSE A.[予備店番]
      END                     AS [予備店番]
FROM ${INFO_DB}.[T_KT05502D_WK] AS A
INNER JOIN ${INFO_DB}.[T_KT05580D_OBJ] AS B
ON (A.[統合番号] = B.[統合番号]);
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
