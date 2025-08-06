#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :LDKA証書貸付ローンを取得                  | HN_INFO.T_KT12050D_WK
# フェーズ          :ＣＩＦ残高
# サイクル          :日次
# 参照テーブル      :LDKA証書貸付ローン                        | HN_V_SRC.T_YS50080D_SRC001
#                    預金ＣＩＦ基本S断面展開                   | HN_INFO.T_KT10100D_OBJ
#                    制度融資商品内訳断面展開                  | HN_INFO.T_KT12010D_OBJ
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
/* LDKA証書貸付集計 作成 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT12050D_WK
SELECT
   T1.[MAKKJB]          AS [作成基準日]
  ,T1.[TBN]             AS [店番]
  ,T1.[CFB]             AS [ＣＩＦ番号]
  ,T1.[KMK]             AS [科目]
  ,T1.[TAKBNG]          AS [取扱番号]
  ,''                   AS [取組番号]
  ,''                   AS [通貨コード]
  ,''                   AS [復活番号]
  ,0                    AS [外為店番]
  ,T3.[HJKCOD]          AS [法個人コード]
  ,T3.[GYSCOD]          AS [業種コード]
  ,T1.[RNGIRE]          AS [稟議一連番号]
  ,T1.[RNGBNG]          AS [稟議協議書番号]
  ,''                   AS [カードローンコード]
  ,''                   AS [種別コード＿預金]
  ,T1.[KZIKBN]          AS [完済区分]
  ,T1.[SDUCOD]          AS [制度融資コード]
  ,T1.[FHSCOD]          AS [付保証コード]
  ,T1.[WKUCOD]          AS [枠コード]
  ,T1.[KKNCOD]          AS [期間コード]
  ,T4.[SHNCOD001]       AS [商品コード１]
  ,T4.[SHNCOD002]       AS [商品コード２]
  ,T4.[SHNCOD003]       AS [商品コード３]
  ,T4.[SHNCOD004]       AS [商品コード４]
  ,T4.[SHNCOD005]       AS [商品コード５]
  ,T4.[SHNCOD006]       AS [商品コード６]
  ,''                   AS [ＷＥＢ口座区分]
  ,T1.[ZAN]             AS [残高]
  ,0                    AS [保証金額]
  ,T1.[FSXKDB]          AS [当初貸出日]
  ,'3'                  AS [作成ＳＱＬ番号]
FROM
  /* 期初日～基準日断面を展開 */
  /* LDKA証書貸付・ローン */
  (SELECT
      [MAKKJB]        /* 作成基準日    KEY*/
     ,[TBN]           /* 店番          KEY*/
     ,[CFB]           /* ＣＩＦ番号    KEY*/
     ,[KMK]           /* 科目          KEY*/
     ,[TAKBNG]        /* 取扱番号      KEY*/
     ,[RNGIRE]        /* 稟議一連番号  KEY*/
     ,[RNGBNG]        /* 稟議番号      KEY*/
     ,[FHSCOD]        /* 付保証コード  */
     ,[WKUCOD]        /* 枠コード      */
     ,[KKNCOD]        /* 期間コード    */
     ,[SDUCOD]        /* 制度融資コード*/
     ,[KZIKBN]        /* 完済区分      */
     ,[ZAN]           /* 残高          */
     ,[FSXKDB]        /* 当初貸出日    */
    FROM ${DB_T_SRC}.T_YS50080D_SRC001
    WHERE  [MAKKJB] >=(SELECT [期初日] FROM ${INFO_DB}.T_KT90085D_OBJ)
      AND  [MAKKJB] <=(SELECT [基準日] FROM ${INFO_DB}.T_KT90085D_OBJ)
  ) AS T1
  /* 預金ＣＩＦ基本S */
  INNER JOIN
  (SELECT * FROM ${INFO_DB}.T_KT10100D_OBJ WHERE [SSSHYJ]='') AS T3
   ON  T1.[MAKKJB] = T3.[作成基準日]
   AND T1.[TBN] = T3.[TBN]
   AND T1.[CFB] = T3.[CFB]
  /* 制度融資商品内訳 */
  INNER JOIN
  ${INFO_DB}.T_KT12010D_OBJ AS T4
  ON  T1.[MAKKJB] = T4.[作成基準日]
  AND T1.[SDUCOD] = T4.[SDUCOD];
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
