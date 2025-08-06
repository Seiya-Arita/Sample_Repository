#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :世帯番号マージWK			| T_NY06201D_WK4	
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :世帯番号マージ				| T_NY06201D_WK1
#    
# 変更履歴
# -------------------------------------------------------------------------
# 2022-03-31        :新規作成                   | Shunya.M
# =========================================================================
#
#  ＳＱＬ実行
#

sqlcmd -S ${SQL_SERVER} -d ${SQL_DB} -U ${SQL_USER} -P ${SQL_PASS} -f ${CHARSET} -t 0 -e -w 300 -b -N o -Q "
DECLARE @ExitCode INT;
DECLARE @ErrorCode INT;
DECLARE @RowCount INT;
SET @ExitCode = 0;
SELECT GETDATE() AS [DATE];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ######################################################################### */
/* #                        世帯番号 マージ  ${CTR} 回目                        # */
/* ######################################################################### */
DELETE FROM ${INFO_DB}.[T_NY06202D_WK2];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
DELETE FROM ${INFO_DB}.[T_NY06203D_WK3];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
DELETE FROM ${INFO_DB}.[T_NY06201D_WK4];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
INSERT INTO ${INFO_DB}.[T_NY06202D_WK2]
SELECT
  A.[世帯番号１],
  MIN(A.[世帯番号２]) AS [ＭＩＮ世帯番号],
  MAX(A.[世帯番号２]) AS [ＭＡＸ世帯番号]
FROM ${INFO_DB}.[T_NY06201D_WK1] AS A
GROUP BY A.[世帯番号１];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
INSERT INTO ${INFO_DB}.[T_NY06203D_WK3]
SELECT
  A.[世帯番号２],
  MIN(A.[世帯番号１]) AS [ＭＩＮ世帯番号],
  MAX(A.[世帯番号１]) AS [ＭＡＸ世帯番号]
FROM ${INFO_DB}.[T_NY06201D_WK1] AS A
GROUP BY A.[世帯番号２];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
INSERT INTO ${INFO_DB}.[T_NY06201D_WK4]
SELECT
  A.[統合ＣＩＦ番号],
  B.[ＭＩＮ世帯番号] AS [世帯番号１],
  C.[ＭＩＮ世帯番号] AS [世帯番号２]
FROM ${INFO_DB}.[T_NY06201D_WK1] AS A
INNER JOIN ${INFO_DB}.[T_NY06202D_WK2] AS B
  ON (A.[世帯番号１] = B.[世帯番号１])
INNER JOIN ${INFO_DB}.[T_NY06203D_WK3] AS C
  ON (A.[世帯番号２] = C.[世帯番号２]);
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
SELECT
  [世帯番号１],
  MIN([世帯番号２]) AS [ＭＩＮ世帯番号],
  MAX([世帯番号２]) AS [ＭＡＸ世帯番号]
FROM ${INFO_DB}.[T_NY06201D_WK4]
GROUP BY [世帯番号１]
HAVING [ＭＩＮ世帯番号] <> [ＭＡＸ世帯番号];
SELECT @ErrorCode = @@ERROR, @RowCount = @@ROWCOUNT;
IF @ErrorCode <> 0 GOTO ENDPT;
IF @RowCount != 0 GOTO RE_MERGE;
SELECT
  [世帯番号２],
  MIN([世帯番号１]) AS [ＭＩＮ世帯番号],
  MAX([世帯番号１]) AS [ＭＡＸ世帯番号]
FROM ${INFO_DB}.[T_NY06201D_WK4]
GROUP BY [世帯番号２]
HAVING [ＭＩＮ世帯番号] <> [ＭＡＸ世帯番号];
SELECT @ErrorCode = @@ERROR, @RowCount = @@ROWCOUNT;
IF @ErrorCode <> 0 GOTO ENDPT;
IF @RowCount != 0 GOTO RE_MERGE;
/* ######################################################################### */
/*                               通常の退出処理                              */
/* ######################################################################### */
SELECT GETDATE() AS [DATE];
SET @ExitCode = 0;
GOTO Final;
/* ######################################################################### */
/*                           再度マージへ                                    */
/* ######################################################################### */
RE_MERGE:
DELETE FROM ${INFO_DB}.[T_NY06201D_WK1];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
INSERT INTO ${INFO_DB}.[T_NY06201D_WK1]
SELECT
  [統合ＣＩＦ番号],
  [世帯番号１],
  [世帯番号２]
FROM ${INFO_DB}.[T_NY06201D_WK4];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
SELECT GETDATE() AS [DATE];
SET @ExitCode = 1;
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
