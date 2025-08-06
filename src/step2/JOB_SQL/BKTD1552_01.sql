#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【管理店】変更依頼管理店情報_バッチ       | HN_INFO.T_KT15520D_OBJ
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :【管理店】変更依頼管理店情報累積          | HN_INFO.T_SN02080D_OBJ
#                   :【管理店】管理店名寄せ情報                | HN_INFO.T_KT15580D_OBJ
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
/* 【管理店】変更依頼管理店情報 作成、抽出 */
/* ****************************************************************** */
WITH RankedData AS (
  SELECT
        D.[統合番号],
        D.[店番],
        D.[ＣＩＦ番号],
        D.[管理店番],
        '02'         AS [管理店番チャネル区分],
        ROW_NUMBER() OVER (PARTITION BY D.[統合番号] ORDER BY D.[変更希望日] DESC,D.[管理番号] DESC,D.[明細番号] DESC,D.[店番],D.[ＣＩＦ番号]) as ranking
  FROM (
      SELECT
            B.[統合番号],
            A.[店番],
            A.[ＣＩＦ番号],
            A.[管理店番],
			      A.[変更希望日],   
            A.[管理番号],    
            A.[明細番号],
            A.[申請区分]
      FROM (
         SELECT
               [勘定店番]       AS [店番],
               [ＣＩＦ番号],
               [変更後管理店番] AS [管理店番],
               [変更希望日],
               [管理番号],
               [明細番号],
               [申請区分]
         FROM ${INFO_DB}.[T_SN02080D_OBJ]
         WHERE [変更希望日] <= (SELECT [前日] FROM ${INFO_DB}.[T_KT00060D_LOAD])
           AND [ジョブ状態] = '承認'
           AND [無効フラグ] = '0'
         ) AS A
      INNER JOIN ${INFO_DB}.[T_KT15580D_OBJ] AS B
      ON (A.[店番] = B.[店番]
      AND A.[ＣＩＦ番号] = B.[ＣＩＦ番号])
      INNER JOIN (
     SELECT
            CAST([TBN] AS DECIMAL(3))   AS [店番]
       FROM ${DB_T_SRC}.[T_SN09100D_SRC001]
      WHERE [MAKKJB] = (SELECT [前日] FROM ${INFO_DB}.[T_KT00060D_LOAD])
       AND  [TBN] <> ''
       AND ([HSB] = ''
        OR (CAST(SUBSTRING([HSB],1,10) AS DECIMAL(8))) > (SELECT [前日] FROM ${INFO_DB}.[T_KT00060D_LOAD]))
     GROUP BY [TBN]
      ) AS C
      ON (A.[管理店番] = C.[店番])
  ) AS D
  WHERE D.申請区分   = '1'
)

INSERT INTO ${INFO_DB}.[T_KT15520D_OBJ]
SELECT
  [統合番号],
  [店番],
  [ＣＩＦ番号],
  [管理店番],
  [管理店番チャネル区分]
FROM
  RankedData
WHERE 
  ranking = 1


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
