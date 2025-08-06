#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 追加テーブル名称  :                   | T_SN00801D_WK1
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :                   | T_SK02010D_SRC001
#                                           ---> T_SK51110D_SRC001
# 参照テーブル      :                   | T_KT00060D_LOAD
#
# 備考              :ＦＧ証券用顧客口座情報作成
#
# 変更履歴
# -------------------------------------------------------------------------
# 2023-02-03        :新規作成           | KDS K.Setoguchi
# 2024-01-25        :下記を変更                              | KDS K.Sakata
#                      ・参照テーブル変更 (T_SK02010D_SRC001
#                                          ---> T_SK51110D_SRC001)
#                      ・参照テーブル変更に伴う抽出条件の変更
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
/*  02_ＦＧ証券契約決済口座取得 */
/* ******************************************************/
INSERT INTO ${INFO_DB}.T_SN00801D_WK1
SELECT
     A.[HOSTBN]                            AS [店番],
     A.[HOSCFB]                            AS [ＣＩＦ番号],
     A.[HOSKMK]                            AS [科目],
     A.[HOSKZB]                            AS [口座番号]
/*  FROM       ${DB_T_SRC}.T_SK02010D_SRC001  A                   2024-01-25  */
FROM ${DB_T_SRC}.T_SK51110D_SRC001  A
CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD  B
WHERE CAST(CAST(B.[前日] AS CHAR(8)) AS DATE) BETWEEN A.[Start_Date] AND A.[End_Date]
  AND A.[Record_Deleted_Flag] = 0
/*      AND  A.SSSHYJ = ''                                        2024-01-25  */
/******************************************************************************/
/*          ( Add extraction condition )                          2024-01-25  */
  AND A.[KZTBEE] <> 0
  AND A.[KZPBEE] = 0
/******************************************************************************/
  AND A.[HOSTBN] <> 0
  AND A.[HOSCFB] <> 0
  AND A.[HOSKMK] <> ''
  AND A.[HOSKZB] <> 0
GROUP BY A.[HOSTBN],A.[HOSCFB],A.[HOSKMK],A.[HOSKZB];
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
