#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【顧客商品有無】生保                       | HN_INFO.T_SN25500D_OBJ
# フェーズ          :生保商品契約有無を判定
# サイクル          :日次
# 参照テーブル      :保険契約明細情報                           | HN_V_SRC.T_SN05570D_SRC001
#                   :業務支援系商品マスタ                       | HN_INFO.T_KT41000D_OBJ
#                   :日付テーブル                               | HN_INFO.T_KT00060D_LOAD
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2025/06/03 新規作成                                           | Kodama
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
/* 顧客商品契約有無情報_生保作成 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_SN25500D_OBJ]
SELECT
   C.[前日]             AS [作成基準日],
   A.[店番]             AS [店番],
   A.[ＣＩＦ番号]       AS [ＣＩＦ番号],
   COALESCE(
     B.[業務商品コード],
     '903' + A.[コード階層区分３] + '00000000'
   )                  AS [商品コード]
FROM
  ( SELECT
       [CIFTBN]         AS [店番],
       [CIFKYABNG]      AS [ＣＩＦ番号],
       CASE
         WHEN [SNESEESHNKBN] = '01' THEN '01' -- 一時払い
         WHEN [SNESEESHNKBN] = '00' THEN '02' -- 平準払い
         ELSE '00'
       END            AS [コード階層区分３],
       RIGHT('00' + LTRIM(RTRIM([SHNZOKCOD])), 8) AS [コード階層区分４]
    FROM ${DB_T_SRC}.[T_SN05570D_SRC001]
    WHERE (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD])
          BETWEEN [Start_Date] AND [End_Date] AND [Record_Deleted_Flag] = 0
      AND [HENSMO] = 'AA'
      AND [DTASRI] NOT IN ('2','3')
      AND [CIFKYABNG] <> '00000000'
      AND CAST([CIFKYABNG] AS NUMERIC) IS NOT NULL
  ) AS A
LEFT JOIN
  ( SELECT
      [コード階層区分３],
      [コード階層区分４],
      [商品コード] AS [業務商品コード]
    FROM ${INFO_DB}.[T_KT41000D_OBJ]
    WHERE [コード階層区分１] = '9'
      AND [コード階層区分２] = '03'
  ) AS B
ON  A.[コード階層区分３] = B.[コード階層区分３]
AND A.[コード階層区分４] = B.[コード階層区分４]
CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS C
GROUP BY C.[前日], A.[店番], A.[ＣＩＦ番号],COALESCE(B.[業務商品コード],'903' + A.[コード階層区分３] + '00000000');
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
