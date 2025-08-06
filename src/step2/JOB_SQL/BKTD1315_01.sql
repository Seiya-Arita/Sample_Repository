#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :保険契約明細断面展開                      | HN_INFO.T_KT13150D_OBJ
# フェーズ          :共通処理
# サイクル          :日次
# 参照テーブル      :保険契約明細情報                          | HN_V_SRC.T_SN05570D_SRC001
#                    基準日累積テーブル                        | HN_INFO.T_KT90080D_OBJ
#                    ＣＩＦ残高基準日テーブル                  | HN_INFO.T_KT90085D_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/10/22 新規作成                                          | H.Okura
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
/* 保険契約明細断面展開 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT13150D_OBJ
SELECT
    B.[基準日]                            AS [作成基準日],
    COALESCE(CAST(A.[CIFTBN] AS NUMERIC),0)     AS [ＣＩＦ店番],
    COALESCE(CAST(A.[CIFKYABNG] AS NUMERIC),0)  AS [ＣＩＦ契約番号],
    A.[NUB]                               AS [通番],
    A.[SHNZOKCOD]                         AS [商品属性コード],
    A.[DTASRI]                            AS [データ種類],
    A.[SNESEESHNKBN]                      AS [資産性商品区分],
    A.[KFNHODTMYSRI]                      AS [基本保険金通貨種類],
    CAST(A.[KFNHENPRI] AS DECIMAL(13,2))  AS [基本保険金額],
    A.[HNLTMYSRI]                         AS [保険料通貨種類],
    CAST(A.[HNL] AS DECIMAL(13,2))        AS [保険料]
FROM
  (SELECT
      [start_date],
      [end_date],
      [CIFTBN],
      [CIFKYABNG],
      [NUB],
      [SHNZOKCOD],
      [DTASRI],
      [SNESEESHNKBN],
      [KFNHODTMYSRI],
      [KFNHENPRI],
      [HNLTMYSRI],
      [HNL]
   FROM ${DB_T_SRC}.T_SN05570D_SRC001 WHERE [Record_Deleted_Flag] = 0
   AND [end_date] >= (SELECT CAST(CAST([期初日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT90085D_OBJ)
  ) AS A
   INNER JOIN
  (
    SELECT CAST(CAST([基準日] AS CHAR(8)) AS DATE) AS [基準日ＤＴ], [基準日] FROM ${INFO_DB}.T_KT90080D_OBJ
    WHERE  [基準日] >= (SELECT [期初日] FROM ${INFO_DB}.T_KT90085D_OBJ)
      AND  [基準日] <= (SELECT [基準日] FROM ${INFO_DB}.T_KT90085D_OBJ)
  ) AS B
   ON B.[基準日ＤＴ] BETWEEN A.[start_date] and A.[end_date];
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
