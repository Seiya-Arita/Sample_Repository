#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【管理店】統合番号親ＣＩＦ                | HN_INFO.T_KT15541D_WK
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :【管理店】管理店名寄せ情報                | HN_INFO.T_KT15580D_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/02/06 新規作成                                          | M.Shunya
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
/* 【管理店】統合番号親ＣＩＦ抽出 */
/* ****************************************************************** */
WITh data AS 
(
      SELECT
            [統合番号],
            [店番],
            [ＣＩＦ番号],
            ROW_NUMBER() OVER (PARTITION BY [統合番号] ORDER BY [代表ＣＩＦフラグ] DESC, [店番], [ＣＩＦ番号]) as row_num
      FROM ${INFO_DB}.[T_KT15580D_OBJ]
)


INSERT INTO ${INFO_DB}.[T_KT15541D_WK]
SELECT
      [統合番号],
      [店番],
      [ＣＩＦ番号]
FROM data
WHERE row_num = 1
UNION ALL
SELECT
      [統合番号],
      [店番],
      [ＣＩＦ番号]
FROM ${INFO_DB}.[T_KT15580D_OBJ]
WHERE [法人個人コード] <> '01';


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
