#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【CC】顧客商品契約有無情報                | T_SN30100D_WKA
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :HDRZ証券投信残高明細                      | V_SK51040D_SRCB01
#                   :LDKA商手情報                              | V_YS50060D_SHN
#                   :LDKA手形貸付情報                          | V_YS50070D_SHN
#                   :LDKA証書・貸付ローン                      | V_YS50080D_SHN
#                   :LDKA支払承諾情報                          | V_YS50090D_SHN
#                   :LDKA代理貸付情報                          | V_YS50100D_SHN
#                   :LDKA融当貸情報作成                        | V_YS50110D_SHN
#                   :CDKA同一人名寄せ                          | V_MA00030D_SRCB01
# 変更履歴
# ------------------------------------------------------------------------------
# 2021-08-23        :新規作成                                  | SVC TSUKINOKI
# 2023-09-19        :抽出条件の変更 (前日→前前日)             | KDS NAKAMITSU
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
/* 【CC】顧客商品有無情報作成（商品追加＿資金調達（制度融資コードベース）） */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_SN30100D_WKA
SELECT
   [作成基準日]           AS [データ基準日],
   [店番]                 AS [店番],
   [ＣＩＦ番号]           AS [ＣＩＦ番号],
   [統合ＣＩＦ番号]       AS [統合ＣＩＦ番号],
   [業務支援系商品コード] AS [商品コード]
FROM
(
  SELECT [作成基準日],[店番],[ＣＩＦ番号],[業務支援系商品コード] FROM ${INFO_DB}.V_YS50060D_SHN
  WHERE [作成基準日]=(SELECT [前前日] FROM ${INFO_DB}.T_KT00060D_LOAD) AND [残高]>0
  UNION
  SELECT [作成基準日],[店番],[ＣＩＦ番号],[業務支援系商品コード] FROM ${INFO_DB}.V_YS50070D_SHN
  WHERE [作成基準日]=(SELECT [前前日] FROM ${INFO_DB}.T_KT00060D_LOAD) AND [残高]>0
  UNION
  SELECT [作成基準日],[店番],[ＣＩＦ番号],[業務支援系商品コード] FROM ${INFO_DB}.V_YS50080D_SHN
  WHERE [作成基準日]=(SELECT [前前日] FROM ${INFO_DB}.T_KT00060D_LOAD) AND [残高]>0
  UNION
  SELECT [作成基準日],[店番],[ＣＩＦ番号],[業務支援系商品コード] FROM ${INFO_DB}.V_YS50090D_SHN
  WHERE [作成基準日]=(SELECT [前前日] FROM ${INFO_DB}.T_KT00060D_LOAD) AND [残高]>0
  UNION
  SELECT [作成基準日],[店番],[ＣＩＦ番号],[業務支援系商品コード] FROM ${INFO_DB}.V_YS50100D_SHN
  WHERE [作成基準日]=(SELECT [前前日] FROM ${INFO_DB}.T_KT00060D_LOAD) AND [残高]>0
  UNION
  SELECT [作成基準日],[店番],[ＣＩＦ番号],[業務支援系商品コード] FROM ${INFO_DB}.V_YS50110D_SHN
  WHERE [作成基準日]=(SELECT [前前日] FROM ${INFO_DB}.T_KT00060D_LOAD) AND [残高]>0
) AS A
INNER JOIN
(
 SELECT
    [店番],
    [ＣＩＦ番号],
    [統合ＣＩＦ番号]
 FROM ${INFO_DB}.V_MA00030D_SRCB01
) AS B
ON  A.[店番]=B.[店番]
AND A.[ＣＩＦ番号]=B.[ＣＩＦ番号];
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
