#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :事業資金積数                              | HN_INFO.T_NY03001D_WK
# フェーズ          :計数集計
# サイクル          :日次
# 参照テーブル      :流動性事業資金月中積数                    | HN_INFO.T_NY03600D_OBJ
#                    YRKA流動性基本S                           | HN_V_SRC.T_YK51010D_SRC001
#                    YRKA預金ＣＩＦ基本S                       | HN_V_SRC.T_YK50060D_SRC001
#                    日付テーブル                              | HN_INFO.T_KT00060D_LOAD
# 変更履歴
# ------------------------------------------------------------------------------
# 2023-02-06        :新規作成                                  | nagata
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
/* 流動性預金 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_NY03001D_WK]
SELECT
   T3.[前日]               AS [作成基準日],
   T1.[TBN]                AS [店番],
   T1.[CFB]                AS [ＣＩＦ番号],
   T1.[KMK]                AS [科目],
   T1.[KZB]                AS [取扱番号],
   ''                      AS [取組番号],
   ''                      AS [通貨コード],
   ''                      AS [復活番号],
   0                       AS [外為店番],
   T2.[HJKCOD]             AS [法個人コード],
   T2.[GYSCOD]             AS [業種コード],
   T1.[CDLCOD]             AS [カードローンコード],
   ''                      AS [付保証コード],
   ''                      AS [商品コード１],
   ''                      AS [商品コード２],
   ''                      AS [商品コード３],
   ''                      AS [商品コード４],
   ''                      AS [商品コード５],
   ''                      AS [商品コード６],
   T4.[月中積数]           AS [当月月中積数],
   '7'                     AS [作成ＳＱＬ番号]
FROM ${INFO_DB}.[T_NY03600D_OBJ] AS T4
INNER JOIN
  ( SELECT * FROM ${DB_T_SRC}.[T_YK51010D_SRC001]
     WHERE ( SELECT CAST(CAST([前前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD] )
           BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
      AND  [KMK] IN ('11','12')
      AND  [SSSHYJ] = ''
  ) AS T1
ON T4.[店番]=T1.[TBN] AND T4.[ＣＩＦ番号]=T1.[CFB] AND T4.[科目]=T1.[KMK] AND T4.[口座番号]=T1.[KZB]
INNER JOIN
  ( SELECT * FROM ${DB_T_SRC}.[T_YK50060D_SRC001]
     WHERE ( SELECT CAST(CAST([前前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD] )
           BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0 AND [SSSHYJ]=''
   ) AS T2
ON  T1.[TBN] = T2.[TBN]
AND T1.[CFB] = T2.[CFB]
CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS T3;
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
