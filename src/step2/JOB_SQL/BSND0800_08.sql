#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 追加テーブル名称  :                   | T_SN00800D_WK1
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :                   | T_YK50060D_SRC001
# 参照テーブル      :                   | T_YK51010D_SRC001
# 更新テーブル      :                   | T_KT00060D_LOAD
#
# 備考              :ＦＧ証券用顧客口座情報作成
#
# 変更履歴
# -------------------------------------------------------------------------
# 2023-02-03        :新規作成           | KDS K.Setoguchi
# 2023-05-18        :項目追加６項目     | KDS K.Sakata
#                        カナ都道府県名桁数
#                        カナ市区郡町村桁数
#                        カナ大字通称桁数
#                        カナ字名丁目桁数
#                        カナ番地桁数
#                        カナ方書桁数
#
# =========================================================================
#
#  ＳＱＬ実行
#

sqlcmd -S ${SQL_SERVER} -d ${SQL_DB} -U ${SQL_USER} -P ${SQL_PASS} -f ${CHARSET} -t 0 -e -b -N o -Q "
DECLARE @ExitCode INT;
DECLARE @ErrorCode INT;
SET @ExitCode = 0;
SELECT GETDATE() AS [DATE];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ******************************************************/
/*  08_顧客情報取得 */
/* ******************************************************/
INSERT INTO ${INFO_DB}.[T_SN00800D_WK1]
SELECT
    C.[前日] AS [作成基準日],
    '' AS [統合ＣＩＦ番号],
    A.[TBN] AS [店番],
    A.[CFB] AS [ＣＩＦ番号],
    CASE WHEN B.[KMK] IS NULL THEN '00' ELSE B.[KMK] END AS [科目],
    CASE WHEN B.[KZB] IS NULL THEN 0 ELSE B.[KZB] END AS [口座番号],
    A.[KNANAM] AS [カナ氏名],
    A.[KJM] AS [漢字氏名],
    A.[BIR] AS [生年月日],
    A.[SEXCOD] AS [性別コード],
    A.[HNNKQNKBN] AS [本人確認区分],
    A.[HNNKQNKVX] AS [本人確認更新日],
    A.[JCD] AS [住所コード],
    A.[YUG] AS [郵便番号],
    '' AS [カナ住所],
    0 AS [カナ都道府県名桁数],
    0 AS [カナ市区郡町村桁数],
    0 AS [カナ大字通称桁数],
    0 AS [カナ字名丁目桁数],
    0 AS [カナ番地桁数],
    0 AS [カナ方書桁数],
    A.[KJX] AS [漢字住所],
    A.[TFMKTA] AS [都道府県名桁数],
    A.[SG0KTA] AS [市区郡町村桁数],
    A.[OAZTUOKTA] AS [大字通称桁数],
    A.[AZMCMEKTA] AS [字名丁目桁数],
    A.[BNCKTA] AS [番地桁数],
    A.[FOGKTA] AS [方書桁数],
    A.[JTQTEL] AS [自宅電話番号],
    A.[KMSTEL] AS [勤務先電話番号],
    A.[KDWBNG] AS [携帯電話番号],
    A.[HJKCOD] AS [法人個人コード],
    A.[GYSCOD] AS [業種コード],
    A.[TRD] AS [登録日＿ＣＩＦ開設日],
    CASE WHEN B.[KZTBEE] IS NULL THEN 0 ELSE B.[KZTBEE] END AS [口座開設日],
    CASE WHEN B.[ENDIDB] IS NULL THEN 0 ELSE B.[ENDIDB] END AS [最終移動日],
    CASE WHEN B.[SBTCOD] IS NULL THEN '' ELSE B.[SBTCOD] END AS [種別コード],
    0 AS [勤務先登録日],
    '' AS [カナ勤務先名],
    '' AS [漢字勤務先名],
    '' AS [統合ＣＩＦ内ＦＧ証券契約],
    '' AS [ＦＧ証券口座契約],
    '' AS [統合ＣＩＦ内ＮＩＳＡ契約],
    '' AS [ＮＩＳＡ契約あり＿銀行契約],
    '' AS [ＮＩＳＡ契約あり＿ＦＧ契約]
FROM
  (SELECT * FROM ${DB_T_SRC}.[T_YK50060D_SRC001]
   WHERE (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD]) BETWEEN [Start_Date] AND [End_Date]
     AND [Record_Deleted_Flag] = 0
     AND [SSSHYJ] = ''
  ) A
LEFT JOIN
  (SELECT * FROM ${DB_T_SRC}.[T_YK51010D_SRC001]
   WHERE (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD]) BETWEEN [Start_Date] AND [End_Date]
     AND [Record_Deleted_Flag] = 0
     AND [SSSHYJ] = ''
  ) B
ON  A.[TBN] = B.[TBN]
AND A.[CFB] = B.[CFB]
CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] C;
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
