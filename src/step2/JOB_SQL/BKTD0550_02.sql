#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【管理店】管理店情報ＷＫ                  | HN_INFO.T_KT05502D_WK
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :管理店情報マージＷＫ                      | HN_INFO.T_KT05501D_WK
#                   :【管理店】管理店名寄せ情報                | HN_INFO.T_KT05580D_OBJ
#                   :店属性                                    | HN_V_SRC.T_SN09100D_SRC001
#                   :【管理店】手動設定管理店情報              | HN_INFO.T_KT05510D_OBJ
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
/* 【管理店】管理店情報 作成 */
/* ****************************************************************** */

WITH unionized AS
(
   SELECT 
         A.[統合番号],
         A.[管理店番] AS [エリア店番],
         ROW_NUMBER() OVER (PARTITION BY A.[統合番号] ORDER BY B.[優先順位]) AS ROW_NB
   FROM (
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
      ) AS A
   INNER JOIN ${INFO_DB}.[T_KT05501Z_OBJ] AS B
   ON (A.[管理店番チャネル区分] = B.[管理店番チャネル区分])
),

Ranked AS
(
   SELECT
         H.[基準日]               AS [作成基準日],
         A.[統合番号],
         A.[店番],
         A.[ＣＩＦ番号],
         A.[管理店番],
         A.[管理店番チャネル区分],
         A.[優先順位],
         ''                     AS [代表ＣＩＦフラグ],
         B.[顧客区分コード],
         B.[住所コード]           AS [住所コード],
         E.[付与情報]             AS [取経先他付与フラグ],
         COALESCE(C.[合算店番],0) AS [ミニブロック店番],
         D.[エリア店番]           AS [予備店番]
   FROM ${INFO_DB}.[T_KT05501D_WK] AS A
   INNER JOIN ${INFO_DB}.[T_KT05580D_OBJ] AS B
   ON (A.[店番] = B.[店番]
   AND A.[ＣＩＦ番号] = B.[ＣＩＦ番号])
   LEFT JOIN (
      SELECT
            [TBN] AS [店番],
            SUBSTRING([GSNTBN],1,3) AS [合算店番]
      FROM ${DB_T_SRC}.[T_SN09100D_SRC001]
      WHERE [MAKKJB] = (SELECT [基準日] FROM ${INFO_DB}.[T_KT00060D_LOAD])
      AND [TBN] <> ''
      AND [GSNTBN] <> ''
      GROUP BY [TBN],[GSNTBN]
   ) AS C
   ON (A.[管理店番] = C.[店番])
   INNER JOIN (
      SELECT 
            [統合番号],
            [エリア店番],
            ROW_NB
      FROM unionized
      WHERE ROW_NB = 1 ) AS D
   ON (A.[統合番号] = D.[統合番号])
   INNER JOIN (
      SELECT 
            A.[統合番号],
            MAX(CASE WHEN A.[管理店番チャネル区分] IN ('06','07')      THEN 1 ELSE 0 END) + MAX(CASE WHEN A.[管理店番チャネル区分] IN ('04','05')      THEN 2 ELSE 0 END) +
            MAX(CASE WHEN A.[管理店番チャネル区分] IN ('01','02','03') THEN 4 ELSE 0 END) AS [付与情報]
      FROM (
         SELECT
               [統合番号],
               [管理店番チャネル区分]
         FROM ${INFO_DB}.[T_KT05510D_OBJ]
         UNION ALL
         SELECT
               [統合番号],
               [管理店番チャネル区分]
         FROM ${INFO_DB}.[T_KT05520D_OBJ]
         UNION ALL
         SELECT
               [統合番号],
               [管理店番チャネル区分]
         FROM ${INFO_DB}.[T_KT05530D_OBJ]
         UNION ALL
         SELECT
               [統合番号],
               [管理店番チャネル区分]
         FROM ${INFO_DB}.[T_KT05540D_OBJ]
         WHERE [管理店番]<>0
         UNION ALL
         SELECT
               [統合番号],
               [管理店番チャネル区分]
         FROM ${INFO_DB}.[T_KT05550D_OBJ]
         UNION ALL
         SELECT
               [統合番号],
               [管理店番チャネル区分]
         FROM ${INFO_DB}.[T_KT05560D_OBJ]
         UNION ALL
         SELECT
               [統合番号],
               [管理店番チャネル区分]
         FROM ${INFO_DB}.[T_KT05570D_OBJ]
      ) AS A
      GROUP BY [統合番号]
   ) AS E
   ON (A.[統合番号] = E.[統合番号])
   CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS H    
)

INSERT INTO ${INFO_DB}.[T_KT05502D_WK]
SELECT
      [作成基準日],
      [統合番号],
      [店番],
      [ＣＩＦ番号],
      [管理店番],
      [管理店番チャネル区分],
      [優先順位],
      [代表ＣＩＦフラグ],
      [顧客区分コード],
      [住所コード],
      [取経先他付与フラグ],
      [ミニブロック店番],
      [予備店番]
FROM Ranked
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
