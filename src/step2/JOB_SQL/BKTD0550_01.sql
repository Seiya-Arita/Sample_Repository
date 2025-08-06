#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :管理店情報マージＷＫ                      | HN_INFO.T_KT05501D_WK
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :【管理店】手動設定管理店情報              | HN_INFO.T_KT05510D_OBJ
#                   :【管理店】変更依頼管理店情報              | HN_INFO.T_KT05520D_OBJ
#                   :【管理店】取経先管理店情報                | HN_INFO.T_KT05530D_OBJ
#                   :【管理店】貸出先管理店情報                | HN_INFO.T_KT05540D_OBJ
#                   :【管理店】地区テリトリ管理店情報          | HN_INFO.T_KT05550D_OBJ
#                   :【管理店】県外エリア管理店情報            | HN_INFO.T_KT05560D_OBJ
#                   :【管理店】代表ＣＩＦ管理店情報            | HN_INFO.T_KT05570D_OBJ
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
/* 【管理店】管理店情報マージ */
/* ****************************************************************** */

With combined AS
(
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT05510D_OBJ]
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT05520D_OBJ]
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT05530D_OBJ]
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT05540D_OBJ]
   WHERE [管理店番]<>0
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT05550D_OBJ]
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT05560D_OBJ]
   UNION ALL
   SELECT
         [統合番号],
         [管理店番],
         [管理店番チャネル区分]
   FROM ${INFO_DB}.[T_KT05570D_OBJ]
     ),

ROW_NUMBERED AS 
(     SELECT 
         A.[統合番号],
         C.[店番],
         C.[ＣＩＦ番号],
         A.[管理店番],
         A.[管理店番チャネル区分],
         B.[優先順位],
         ROW_NUMBER() OVER (PARTITION BY A.[統合番号] ORDER BY B.[優先順位]) AS  ROW_NB
      FROM combined AS A
      INNER JOIN ${INFO_DB}.[T_KT05501Z_OBJ] AS B
      ON (A.[管理店番チャネル区分] = B.[管理店番チャネル区分])
      INNER JOIN ${INFO_DB}.[T_KT05570D_OBJ] AS C
      ON (A.[統合番号] = C.[統合番号])
)

INSERT INTO ${INFO_DB}.[T_KT05501D_WK]
SELECT
      [統合番号],
      [店番],
      [ＣＩＦ番号],
      [管理店番],
      [管理店番チャネル区分],
      [優先順位]
FROM ROW_NUMBERED
WHERE 1 = ROW_NB
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
