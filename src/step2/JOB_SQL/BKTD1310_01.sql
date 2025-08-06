#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :ＣＩＦ残高預り資産                        | HN_INFO.T_KT13100D_OBJ
# フェーズ          :ＣＩＦ残高
# サイクル          :日次
# 参照テーブル      :預り資産計数集約                          | HN_INFO.T_KT13070D_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/10/30 新規作成                                          | H.Okura
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
/* ＣＩＦ残高預り資産 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.T_KT13100D_OBJ
SELECT
     A.[作成基準日] AS [作成基準日]
    ,A.[TBN] AS [店番]
    ,A.[CFB] AS [ＣＩＦ番号]
    ,MAX(CASE WHEN B.[商品コード]='3050200000000' THEN B.[残高]     ELSE 0 END) AS [公共債残高]
    ,MAX(CASE WHEN B.[商品コード]='3050200000000' THEN B.[月中積数] ELSE 0 END) AS [公共債月中積数]
    ,MAX(CASE WHEN B.[商品コード]='3050200000000' THEN B.[月中平残] ELSE 0 END) AS [公共債月中平残]
    ,MAX(CASE WHEN B.[商品コード]='3050200000000' THEN B.[期中積数] ELSE 0 END) AS [公共債期中積数]
    ,MAX(CASE WHEN B.[商品コード]='3050200000000' THEN B.[期中平残] ELSE 0 END) AS [公共債期中平残]
    ,MAX(CASE WHEN B.[商品コード]='3050300000000' THEN B.[残高]     ELSE 0 END) AS [当行投信残高]
    ,MAX(CASE WHEN B.[商品コード]='3050300000000' THEN B.[月中積数] ELSE 0 END) AS [当行投信月中積数]
    ,MAX(CASE WHEN B.[商品コード]='3050300000000' THEN B.[月中平残] ELSE 0 END) AS [当行投信月中平残]
    ,MAX(CASE WHEN B.[商品コード]='3050300000000' THEN B.[期中積数] ELSE 0 END) AS [当行投信期中積数]
    ,MAX(CASE WHEN B.[商品コード]='3050300000000' THEN B.[期中平残] ELSE 0 END) AS [当行投信期中平残]
    ,MAX(CASE WHEN B.[商品コード]='3050400000000' THEN B.[残高]     ELSE 0 END) AS [生命保険一時払残高]
    ,MAX(CASE WHEN B.[商品コード]='3050400000000' THEN B.[月中積数] ELSE 0 END) AS [生命保険一時払月中積数]
    ,MAX(CASE WHEN B.[商品コード]='3050400000000' THEN B.[月中平残] ELSE 0 END) AS [生命保険一時払月中平残]
    ,MAX(CASE WHEN B.[商品コード]='3050400000000' THEN B.[期中積数] ELSE 0 END) AS [生命保険一時払期中積数]
    ,MAX(CASE WHEN B.[商品コード]='3050400000000' THEN B.[期中平残] ELSE 0 END) AS [生命保険一時払期中平残]
    ,MAX(CASE WHEN B.[商品コード]='3100000000000' THEN B.[残高]     ELSE 0 END) AS [ＦＧ投信残高]
    ,MAX(CASE WHEN B.[商品コード]='3100000000000' THEN B.[月中積数] ELSE 0 END) AS [ＦＧ投信月中積数]
    ,MAX(CASE WHEN B.[商品コード]='3100000000000' THEN B.[月中平残] ELSE 0 END) AS [ＦＧ投信月中平残]
    ,MAX(CASE WHEN B.[商品コード]='3100000000000' THEN B.[期中積数] ELSE 0 END) AS [ＦＧ投信期中積数]
    ,MAX(CASE WHEN B.[商品コード]='3100000000000' THEN B.[期中平残] ELSE 0 END) AS [ＦＧ投信期中平残]
    ,MAX(CASE WHEN B.[商品コード]='9080000000000' THEN B.[残高]     ELSE 0 END) AS [ＦＧ債券残高]
    ,MAX(CASE WHEN B.[商品コード]='9080000000000' THEN B.[月中積数] ELSE 0 END) AS [ＦＧ債券月中積数]
    ,MAX(CASE WHEN B.[商品コード]='9080000000000' THEN B.[月中平残] ELSE 0 END) AS [ＦＧ債券月中平残]
    ,MAX(CASE WHEN B.[商品コード]='9080000000000' THEN B.[期中積数] ELSE 0 END) AS [ＦＧ債券期中積数]
    ,MAX(CASE WHEN B.[商品コード]='9080000000000' THEN B.[期中平残] ELSE 0 END) AS [ＦＧ債券期中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZSZYAZKRGOKEI' THEN B.[残高]     ELSE 0 END) AS [市場性預り資産合計残高]
    ,MAX(CASE WHEN B.[商品コード]='ZSZYAZKRGOKEI' THEN B.[月中積数] ELSE 0 END) AS [市場性預り資産合計月中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZSZYAZKRGOKEI' THEN B.[月中平残] ELSE 0 END) AS [市場性預り資産合計月中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZSZYAZKRGOKEI' THEN B.[期中積数] ELSE 0 END) AS [市場性預り資産合計期中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZSZYAZKRGOKEI' THEN B.[期中平残] ELSE 0 END) AS [市場性預り資産合計期中平残]
    ,MAX(CASE WHEN B.[商品コード]='3060000000000' THEN B.[残高]     ELSE 0 END) AS [信託財産残高]
    ,MAX(CASE WHEN B.[商品コード]='3060000000000' THEN B.[月中積数] ELSE 0 END) AS [信託財産月中積数]
    ,MAX(CASE WHEN B.[商品コード]='3060000000000' THEN B.[月中平残] ELSE 0 END) AS [信託財産月中平残]
    ,MAX(CASE WHEN B.[商品コード]='3060000000000' THEN B.[期中積数] ELSE 0 END) AS [信託財産期中積数]
    ,MAX(CASE WHEN B.[商品コード]='3060000000000' THEN B.[期中平残] ELSE 0 END) AS [信託財産期中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZZZZAZKRGOKEI' THEN B.[残高]     ELSE 0 END) AS [預り資産合計残高]
    ,MAX(CASE WHEN B.[商品コード]='ZZZZAZKRGOKEI' THEN B.[月中積数] ELSE 0 END) AS [預り資産合計月中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZZZZAZKRGOKEI' THEN B.[月中平残] ELSE 0 END) AS [預り資産合計月中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZZZZAZKRGOKEI' THEN B.[期中積数] ELSE 0 END) AS [預り資産合計期中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZZZZAZKRGOKEI' THEN B.[期中平残] ELSE 0 END) AS [預り資産合計期中平残]
FROM
(SELECT [作成基準日],[TBN],[CFB] FROM ${INFO_DB}.T_KT10100D_OBJ
 WHERE [作成基準日]=(SELECT [基準日] FROM ${INFO_DB}.T_KT90085D_OBJ)) AS A
LEFT JOIN
(SELECT [店番],[ＣＩＦ番号],[商品コード]
       ,[残高],[月中積数],[月中平残],[期中積数],[期中平残]
 FROM ${INFO_DB}.T_KT13070D_OBJ) AS B
ON  A.[TBN]=B.[店番]
AND A.[CFB]=B.[ＣＩＦ番号]
GROUP BY A.[作成基準日],A.[TBN],A.[CFB];
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
