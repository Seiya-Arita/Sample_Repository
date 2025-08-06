#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【管理店】管理店名寄せ情報                | HN_INFO.T_KT15580D_OBJ
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :ＣＩＦ基本情報                            | HN_V_SRC.T_YK50060D_SRC001
#                   :同一人名寄せ                              | HN_V_SRC.T_MA00030M_SRC001
#                   :日付テーブル                              | HN_INFO.T_KT00080D_LOAD
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/09/30 新規作成                                          | M.Shunya
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
/* 【管理店】管理店名寄せ情報 作成 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT15580D_OBJ]
SELECT
      CASE WHEN [法人個人コード] = '01'
           THEN
               B.[DEC統合ＣＩＦ番号]
           ELSE
               A.[店番] * 10000000000 + LEFT(A.[ＣＩＦ番号], datalength(A.[ＣＩＦ番号])/4)
      END                AS [統合番号],
      B.[統合ＣＩＦ番号],
      A.[店番],
      A.[ＣＩＦ番号],
      B.[代表ＣＩＦフラグ],
      A.[住所コード],
      SUBSTRING(dbo.FORMAT2(A.[住所コード],'99999999999'),1,2) AS [住所コード上位２桁],
      A.[法人個人コード],
      A.[業種コード],
      CASE WHEN A.[法人個人コード] = '01'
           THEN
               CASE WHEN SUBSTRING(A.[業種コード],1,2) = '14' OR A.[業種コード] = '170100'
                    THEN '1'
                    ELSE '2'
               END
           ELSE '3'
      END                    AS [顧客区分コード]
FROM (
   SELECT
         [TBN]    AS [店番],
         [CFB]    AS [ＣＩＦ番号],
         [JCD]    AS [住所コード],
         [HJKCOD] AS [法人個人コード],
         [GYSCOD] AS [業種コード]
   FROM ${DB_T_SRC}.[T_YK50060D_SRC001]
   WHERE [Record_Deleted_Flag] = 0
     AND (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD])
          BETWEEN [Start_Date] AND [End_Date]
     AND [SSSHYJ] = ''
   ) AS A
INNER JOIN (
   SELECT
         CAST([Intg_Cif_No] AS DECIMAL(11,0)) AS [DEC統合ＣＩＦ番号],
         [Intg_Cif_No] AS [統合ＣＩＦ番号],
         [Brnch_Cd]    AS [店番],
         [Cif_No]      AS [ＣＩＦ番号],
         [Delg_Cif_Fl] AS [代表ＣＩＦフラグ]
   FROM ${DB_T_SRC}.[T_MA00030M_SRC001]
   WHERE [Record_Deleted_Flag] = 0
     AND (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD])
          BETWEEN [Start_Date] AND [End_Date]
   ) AS B
ON (A.[店番] = B.[店番]
AND A.[ＣＩＦ番号] = B.[ＣＩＦ番号])
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
