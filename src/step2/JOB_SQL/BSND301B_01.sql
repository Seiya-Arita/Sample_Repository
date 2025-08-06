#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【CC】顧客商品契約有無情報                | T_SN30100D_WKB
# フェーズ          :CDカード利用者情報抽出
# サイクル          :日次
# 参照テーブル      :YRKAＣＤカード契約S                       | T_YK51590D_SRC001
#                   :YRKA流動性基本                            | T_YK51010D_SRC001
#                   :CDKA同一人名寄せ                          | V_MA00030D_SRCB01
#                   :顧客商品有無コード変換                    | T_SN30150Z_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2023-01-23        :新規作成                                  | KODAMA
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
/* 【CC】顧客商品有無情報作成（商品追加＿機能サービス） */
/*  CDカード利用者情報抽出 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_SN30100D_WKB]
SELECT
  T3.[作成基準日]      AS [作成基準日]
 ,T3.[店番]            AS [店番]
 ,T3.[ＣＩＦ番号]      AS [ＣＩＦ番号]
 ,T7.[統合ＣＩＦ番号]  AS [統合ＣＩＦ番号]
 ,T8.[商品コード]      AS [商品コード]
FROM
  ( SELECT
      T2.[前日]        AS [作成基準日]
     ,T1.[TBN]         AS [店番]
     ,T1.[CFB]         AS [ＣＩＦ番号]
     ,T1.[KMK]         AS [科目]
     ,T1.[KZB]         AS [口座番号]
     ,T1.[CDDCDS]      AS [ＣＤカード種類]
    FROM       ${DB_T_SRC}.[T_YK51590D_SRC001] AS T1
    CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD]    AS T2
    WHERE CAST(CAST(T2.[前日] AS CHAR(8)) AS DATE)
          BETWEEN T1.[Start_Date] AND T1.[End_Date] AND T1.[Record_Deleted_Flag] = 0
    AND  T1.[HDQ] = '1'
    AND  T1.[SSSHYJ] <> '1'
  ) AS T3
INNER JOIN
  ( SELECT
      T4.[TBN]         AS [店番]
     ,T4.[CFB]   AS [ＣＩＦ番号]
     ,T4.[KMK]         AS [科目]
     ,T4.[KZB]     AS [口座番号]
    FROM       ${DB_T_SRC}.[T_YK51010D_SRC001] AS T4
    CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD]    AS T5
    WHERE CAST(CAST(T5.[前日] AS CHAR(8)) AS DATE)
          BETWEEN T4.[Start_Date] AND T4.[End_Date] AND T4.[Record_Deleted_Flag] = 0
    AND  T4.[SSSHYJ] <> '1'
  ) AS T6
ON  T3.[店番]       = T6.[店番]
AND T3.[ＣＩＦ番号] = T6.[ＣＩＦ番号]
AND T3.[科目]       = T6.[科目]
AND T3.[口座番号]   = T6.[口座番号]
INNER JOIN
  ${INFO_DB}.[V_MA00030D_SRCB01] AS T7
ON  T3.[店番]       = T7.[店番]
AND T3.[ＣＩＦ番号] = T7.[ＣＩＦ番号]
INNER JOIN
  ( SELECT [変換前コード], [商品コード]
    FROM  ${INFO_DB}.[T_SN30150Z_OBJ]
    WHERE  [種別] = '03'
  ) AS T8
ON  T3.[ＣＤカード種類] = T8.[変換前コード]
GROUP BY T3.[作成基準日], T3.[店番], T3.[ＣＩＦ番号], T7.[統合ＣＩＦ番号], T8.[商品コード];
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
