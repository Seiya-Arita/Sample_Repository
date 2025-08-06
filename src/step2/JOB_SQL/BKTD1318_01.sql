#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :金銭信託断面展開                          | HN_INFO.T_KT13180D_OBJ
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :金銭信託情報                              | HN_V_SEM.T_SN02750D_SEM001
#                    基準日累積テーブル                        | HN_INFO.T_KT90080D_OBJ
#                    ＣＩＦ残高基準日テーブル                  | HN_INFO.T_KT90085D_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/10/22 新規作成                                          | H.Okura
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
/* 保険契約明細断面展開 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT13180D_OBJ
SELECT
    B.[基準日]         AS [作成基準日],
    A.[TBN]            AS [店番],
    A.[CFB]            AS [ＣＩＦ番号],
    A.[SWIBNG]         AS [信託番号],
    A.[BUNCOD]         AS [分類コード],
    A.[JEKCAICOD]      AS [受益権階層コード],
    A.[JEKBNG]         AS [受益権番号],
    A.[SWISTB]         AS [信託設定日],
    A.[SWIMRB]         AS [信託満了日],
    A.[FSXSWIKGK]      AS [当初＿信託金額],
    A.[KJBSWIGPN]      AS [基準日＿信託元本],
    A.[YGNDIYTYAUMU]   AS [遺言代用特約の有無],
    A.[DIKHTDUMU]      AS [代理権発動有無]
FROM
  (SELECT
      [start_date],
      [end_date],
      [TBN],
      [CFB],
      [SWIBNG],
      [BUNCOD],
      [JEKCAICOD],
      [JEKBNG],
      [SWISTB],
      [SWIMRB],
      [FSXSWIKGK],
      [KJBSWIGPN],
      [YGNDIYTYAUMU],
      [DIKHTDUMU]
   FROM ${DB_T_SEM}.T_SN02750D_SEM001 WHERE [Record_Deleted_Flag] = 0
   AND [end_date] >= (SELECT CAST(CAST([期初日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT90085D_OBJ)
  ) AS A
   INNER JOIN
  (
    SELECT CAST(CAST([基準日] AS CHAR(8)) AS DATE) AS [基準日ＤＴ], [基準日] FROM ${INFO_DB}.T_KT90080D_OBJ
    WHERE  [基準日] >= (SELECT [期初日] FROM ${INFO_DB}.T_KT90085D_OBJ)
      AND  [基準日] <= (SELECT [基準日] FROM ${INFO_DB}.T_KT90085D_OBJ)
  ) AS B
   ON B.[基準日ＤＴ] BETWEEN A.[start_date] and A.[end_date];
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
