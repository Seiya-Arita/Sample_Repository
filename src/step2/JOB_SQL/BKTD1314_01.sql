#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :投信残高属性断面展開                      | HN_INFO.T_KT13140D_OBJ
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :【BestWay】投信口座残高属性情報           | HN_V_SEM.OM01020D_SEM001
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
/* 投信残高属性断面展開 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT13140D_OBJ]
SELECT
    B.[基準日]               AS [作成基準日],
    A.[BtnCD]                AS [部店コード],
    A.[ActNo]                AS [口座番号],
    A.[FundCD]               AS [ファンドコード],
    A.[FundName]             AS [ファンド名称],
    A.[TokuAzuKbn]           AS [特定預り区分],
    A.[TosiFrom_D]           AS [投資開始日],
    A.[Lst_Yak_D]            AS [直近購入日],
    A.[HOSTBN]               AS [引落店番],
    A.[HOSCFB]               AS [引落ＣＩＦ番号],
    A.[HOSKMK]               AS [引落科目],
    A.[HOSKZB]               AS [引落口座番号],
    A.[HyoukaKin]            AS [評価金額_約定_chya]
FROM
  (SELECT
      [start_date],
      [end_date],
      [BtnCD],
      [ActNo],
      [FundCD],
      [FundName],
      [TokuAzuKbn],
      [TosiFrom_D],
      [Lst_Yak_D],
      [HOSTBN],
      [HOSCFB],
      [HOSKMK],
      [HOSKZB],
      [HyoukaKin]
   FROM ${DB_T_SEM}.[T_OM01020D_SEM001] WHERE [Record_Deleted_Flag] = 0
   AND [end_date] >= (SELECT CAST(CAST([期初日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT90085D_OBJ])
  ) AS A
   INNER JOIN
  (
    SELECT CAST(CAST([基準日] AS CHAR(8)) AS DATE) AS [基準日ＤＴ], [基準日] FROM ${INFO_DB}.[T_KT90080D_OBJ]
    WHERE  [基準日] >= (SELECT [期初日] FROM ${INFO_DB}.[T_KT90085D_OBJ])
      AND  [基準日] <= (SELECT [基準日] FROM ${INFO_DB}.[T_KT90085D_OBJ])
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
