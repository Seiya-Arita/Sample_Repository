#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :ユーザ情報抽出					| T_IM00020D_OBJ
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :アカウントテーブル				| T_SN09000D_SRC001
#                   :日付							| T_KT00060D_LOAD
#
# 変更履歴
# -------------------------------------------------------------------------
# 2021-10-13        :新規作成                       | MST Nishijima
# 2024-08-05        :アカウント情報変更、在籍者削除 | MST Susaki
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
INSERT INTO ${INFO_DB}.T_IM00020D_OBJ
SELECT D.[基準日] AS [作成基準日],
       C.[USRIDE] AS [行員番号],
       SUBSTRING(C.[GYOSYRTBN],1,3) AS [支店コード],
       CASE WHEN C.[KNGLVL] <= '400' THEN '998'
            WHEN C.[KNGLVL] >= '910' AND C.[GYOSYRTBN] IN ('0410', '0420') THEN '000'
            ELSE C.[KNGLVL] END AS [権限レベル]
FROM ${DB_T_SRC}.T_SN09000D_SRC001 AS C
CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD AS D
WHERE (CAST(CAST(D.[基準日] AS CHAR(8)) AS DATE)) BETWEEN C.[Start_Date] AND C.[End_Date]
AND C.[Record_Deleted_Flag] = '0'
AND C.[LDN] LIKE '%肥後銀行%'
AND C.[USRIDE] < 9990000
AND TRIM(C.[KNGLVL]) <> ''
AND C.[GYOSYRTBN] <> '9750'
AND C.[YKYMEL] NOT LIKE '%協力会社%';
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
