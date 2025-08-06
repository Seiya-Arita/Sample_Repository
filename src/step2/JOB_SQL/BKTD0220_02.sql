#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :保険商品コード採番ワーク                | T_KT41010D_WK20
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :生保契約明細情報                        | T_SN05570D_SRC001
#
#
# 変更履歴
# -------------------------------------------------------------------------------------------
# 2021-08-30        :新規作成                                                 | SVC TSUKINOKI
# 2025-05-13        :参照テーブル変更(T_CM60050D_SRC001⇒T_SN05570D_SRC001)   | Yuno
# ===========================================================================================
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
/* 生保契約明細情報                                               */
/* 損害保険・商品コード自動採番                                   */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT41010D_WK20]
SELECT
   Q.[前日],
   Q.[コード階層区分１],
   Q.[コード階層名称１],
   Q.[コード階層区分２],
   Q.[コード階層名称２],
   Q.[コード階層区分３],
   Q.[コード階層名称３],
   Q.[コード階層区分４],
   Q.[コード階層名称４],
   Q.[コード階層区分１] + Q.[コード階層区分２] + Q.[コード階層区分３] + Q.[コード階層区分４] AS [商品コード],
   Q.[商品名称],
   Q.[連番]
FROM (
   SELECT
      DTE.[前日],
      '9' AS [コード階層区分１],
      '資産運用' AS [コード階層名称１],
      '04' AS [コード階層区分２],
      '損害保険' AS [コード階層名称２],
      CASE WHEN PRT.[保険種目]='01' THEN '01'
           WHEN PRT.[保険種目]='04' THEN '02'
           ELSE '00'
      END AS [コード階層区分３],
      CASE WHEN PRT.[保険種目]='01' THEN '火災保険'
           WHEN PRT.[保険種目]='04' THEN '傷害保険'
           ELSE ''
      END AS [コード階層名称３],
      RIGHT(PRT.[商品属性コード],8) AS [コード階層区分４],
      TRIM(PRT.[商品名]) AS [コード階層名称４],
      TRIM(PRT.[商品名]) AS [商品名称],
      ROW_NUMBER() OVER (PARTITION BY [商品属性コード] ORDER BY [商品名]) AS [連番],
      PRT.[商品属性コード]
   FROM
   (
      SELECT
         '00' + TRIM([SHNZOKCOD]) AS [商品属性コード],
         TRIM([SHNMEI]) AS [商品名],
         [HENSMO] AS [保険種目]
      FROM ${DB_T_SRC}.[T_SN05570D_SRC001]
      WHERE (SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.[T_KT00060D_LOAD])
            BETWEEN [Start_Date] AND [End_Date]
        AND [Record_Deleted_Flag]=0
        AND [HENSMO] IN ('01','04')
      GROUP BY '00' + TRIM([SHNZOKCOD]), TRIM([SHNMEI]), [HENSMO]
   ) AS PRT
   CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS DTE
) AS Q;
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
