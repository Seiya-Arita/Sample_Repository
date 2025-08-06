#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :事業資金積数                              | HN_INFO.T_NY03001D_WK
# フェーズ          :計数集計
# サイクル          :日次
# 参照テーブル      :LDKA代理貸付情報                          | HN_V_SRC.T_YS50100D_SRC001
#                    預金ＣＩＦ基本S                           | HN_V_SRC.T_YK50060D_SRC001
#                    制度融資商品内訳                          | HN_V_SRC.T_SN00030D_SRC001
#                    日付テーブル                              | HN_INFO.T_KT00060D_LOAD
# 変更履歴
# ------------------------------------------------------------------------------
# 2022-05-12        :新規作成                                  | eBP Kodama
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
/* LDKA代理貸付 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_NY03001D_WK]
SELECT
   T4.[前日]            AS [作成基準日],
   T1.[TBN]             AS [店番],
   T1.[CFB]             AS [ＣＩＦ番号],
   T1.[KMK]             AS [科目],
   T1.[TAKBNG]          AS [取扱番号],
   ''                   AS [取組番号],
   ''                   AS [通貨コード],
   ''                   AS [復活番号],
   0                    AS [外為店番],
   T2.[HJKCOD]          AS [法個人コード],
   T2.[GYSCOD]          AS [業種コード],
   ''                   AS [カードローンコード],
   T1.[FHSCOD]          AS [付保証コード],
   T3.[SHNCOD001]       AS [商品コード１],
   T3.[SHNCOD002]       AS [商品コード２],
   T3.[SHNCOD003]       AS [商品コード３],
   T3.[SHNCOD004]       AS [商品コード４],
   T3.[SHNCOD005]       AS [商品コード５],
   T3.[SHNCOD006]       AS [商品コード６],
   T1.[GCS]             AS [月中積数],
   '5'                  AS [作成ＳＱＬ番号]
FROM
  ( SELECT * FROM ${DB_T_SRC}.[T_YS50100D_SRC001]
    WHERE [MAKKJB] = ( SELECT [前前日] FROM ${INFO_DB}.[T_KT00060D_LOAD] ) AND
          [GCS] > 0
  ) AS T1
INNER JOIN
  ( SELECT * FROM ${DB_T_SRC}.[T_YK50060D_SRC001]
     WHERE ( SELECT CAST(CAST([前前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD] )
           BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0 AND [SSSHYJ]=''
   ) AS T2
ON  T1.[TBN] = T2.[TBN]
AND T1.[CFB] = T2.[CFB]
INNER JOIN
  ( SELECT * FROM ${DB_T_SRC}.[T_SN00030D_SRC001]
     WHERE ( SELECT CAST(CAST([前前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD] )
           BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
   ) AS T3
ON T1.[SDUCOD] = T3.[SDUCOD]
CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS T4;
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
