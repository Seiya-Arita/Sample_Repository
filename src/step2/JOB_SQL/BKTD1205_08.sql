#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :GDKA異動明細を取得                        | HN_INFO.T_KT12050D_WK
# フェーズ          :ＣＩＦ残高
# サイクル          :日次
# 参照テーブル      :GDKA異動明細                              | HN_V_SRC.T_GK50020D_SRC001
#                    基準日テーブル                            | HN_INFO.T_KT90085D_OBJ
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/07/08 新規作成                                          | TSUKINOKI
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
/* GDKA異動明細集計 作成 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT12050D_WK]
SELECT
   T1.[MAKKJB]          AS [作成基準日],
   T1.[TTGTBN]          AS [店番],
   T1.[KNDTRSBNG]       AS [ＣＩＦ番号],
   T1.[KCDNIB]          AS [科目],
   0                    AS [取扱番号],
   T1.[TR5]             AS [取組番号],
   T1.[TWCCOD]          AS [通貨コード],
   T1.[FKTBNG]          AS [復活番号],
   T1.[GTMTBN]          AS [外為店番],
   ''                   AS [法個人コード],
   ''                   AS [業種コード],
   0                    AS [稟議一連番号],
   0                    AS [稟議協議書番号],
   ''                   AS [カードローンコード],
   ''                   AS [種別コード＿預金],
   ''                   AS [完済区分],
   ''                   AS [制度融資コード],
   ''                   AS [付保証コード],
   ''                   AS [枠コード],
   ''                   AS [期間コード],
   ''                   AS [商品コード１],
   ''                   AS [商品コード２],
   ''                   AS [商品コード３],
   ''                   AS [商品コード４],
   ''                   AS [商品コード５],
   ''                   AS [商品コード６],
   ''                   AS [ＷＥＢ口座区分],
   T1.[EQAZAN]          AS [残高],
   0                    AS [保証金額],
   T1.[KYATEB]          AS [当初貸出日],
   '8'                  AS [作成ＳＱＬ番号]
FROM
  /* 期初日～基準日断面を展開 */
  /* GDKA異動明細 */
  (SELECT
      [MAKKJB],        /* 作成基準日           */
      [TTGTBN],        /* 取次店番        KEY  */
      [KNDTRSBNG],     /* 国内取引先番号  KEY  */
      [KCDNIB],        /* 科目            KEY  */
      [TR5],           /* 取組番号        KEY  */
      [TWCCOD],        /* 通貨コード      KEY  */
      [FKTBNG],        /* 復活番号        KEY  */
      [GTMTBN],        /* 外為店番        KEY  */
      [EQAZAN],        /* 円貨残高             */
      [KYATEB]         /* 契約締結日           */
   FROM ${DB_T_SRC}.[T_GK50020D_SRC001]
   WHERE [MAKKJB] >= (SELECT [期初日] FROM ${INFO_DB}.[T_KT90085D_OBJ])
     AND [MAKKJB] <= (SELECT [基準日] FROM ${INFO_DB}.[T_KT90085D_OBJ])
  ) AS T1;
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
