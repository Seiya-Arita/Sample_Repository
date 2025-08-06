#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :ＣＩＦ残高預金                            | HN_INFO.T_KT11100D_OBJ
# フェーズ          :ＣＩＦ残高
# サイクル          :日次
# 参照テーブル      :預金計数集約                              | HN_INFO.T_KT11070D_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2024/07/08 新規作成                                          | TSUKINOKI
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
/* ＣＩＦ残高預金 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT11100D_OBJ]
SELECT
     A.[作成基準日] AS [作成基準日]
    ,A.[TBN] AS [店番]
    ,A.[CFB] AS [ＣＩＦ番号]
    ,MAX(CASE WHEN B.[商品コード]='1010000000000' THEN B.[残高]     ELSE 0 END) AS [当座預金残高]
    ,MAX(CASE WHEN B.[商品コード]='1010000000000' THEN B.[月中積数] ELSE 0 END) AS [当座預金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='1010000000000' THEN B.[月中平残] ELSE 0 END) AS [当座預金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='1010000000000' THEN B.[期中積数] ELSE 0 END) AS [当座預金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='1010000000000' THEN B.[期中平残] ELSE 0 END) AS [当座預金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='1020000000000' THEN B.[残高]     ELSE 0 END) AS [普通預金残高]
    ,MAX(CASE WHEN B.[商品コード]='1020000000000' THEN B.[月中積数] ELSE 0 END) AS [普通預金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='1020000000000' THEN B.[月中平残] ELSE 0 END) AS [普通預金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='1020000000000' THEN B.[期中積数] ELSE 0 END) AS [普通預金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='1020000000000' THEN B.[期中平残] ELSE 0 END) AS [普通預金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='3010000000000' THEN B.[残高]     ELSE 0 END) AS [通知預金残高]
    ,MAX(CASE WHEN B.[商品コード]='3010000000000' THEN B.[月中積数] ELSE 0 END) AS [通知預金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='3010000000000' THEN B.[月中平残] ELSE 0 END) AS [通知預金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='3010000000000' THEN B.[期中積数] ELSE 0 END) AS [通知預金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='3010000000000' THEN B.[期中平残] ELSE 0 END) AS [通知預金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZZZZZBETSUDAN' THEN B.[残高]     ELSE 0 END) AS [別段預金残高]
    ,MAX(CASE WHEN B.[商品コード]='ZZZZZBETSUDAN' THEN B.[月中積数] ELSE 0 END) AS [別段預金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZZZZZBETSUDAN' THEN B.[月中平残] ELSE 0 END) AS [別段預金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZZZZZBETSUDAN' THEN B.[期中積数] ELSE 0 END) AS [別段預金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZZZZZBETSUDAN' THEN B.[期中平残] ELSE 0 END) AS [別段預金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZZNOZEIJYUNBI' THEN B.[残高]     ELSE 0 END) AS [納税準備預金残高]
    ,MAX(CASE WHEN B.[商品コード]='ZZNOZEIJYUNBI' THEN B.[月中積数] ELSE 0 END) AS [納税準備預金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZZNOZEIJYUNBI' THEN B.[月中平残] ELSE 0 END) AS [納税準備預金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZZNOZEIJYUNBI' THEN B.[期中積数] ELSE 0 END) AS [納税準備預金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZZNOZEIJYUNBI' THEN B.[期中平残] ELSE 0 END) AS [納税準備預金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='2050000000000' THEN B.[残高]     ELSE 0 END) AS [貯蓄預金残高]
    ,MAX(CASE WHEN B.[商品コード]='2050000000000' THEN B.[月中積数] ELSE 0 END) AS [貯蓄預金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='2050000000000' THEN B.[月中平残] ELSE 0 END) AS [貯蓄預金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='2050000000000' THEN B.[期中積数] ELSE 0 END) AS [貯蓄預金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='2050000000000' THEN B.[期中平残] ELSE 0 END) AS [貯蓄預金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='ENKARYUDOYOKN' THEN B.[残高]     ELSE 0 END) AS [円貨流動性預金残高]
    ,MAX(CASE WHEN B.[商品コード]='ENKARYUDOYOKN' THEN B.[月中積数] ELSE 0 END) AS [円貨流動性預金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='ENKARYUDOYOKN' THEN B.[月中平残] ELSE 0 END) AS [円貨流動性預金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='ENKARYUDOYOKN' THEN B.[期中積数] ELSE 0 END) AS [円貨流動性預金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='ENKARYUDOYOKN' THEN B.[期中平残] ELSE 0 END) AS [円貨流動性預金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='2060000000001' THEN B.[残高]     ELSE 0 END) AS [一般定期通帳式残高]
    ,MAX(CASE WHEN B.[商品コード]='2060000000001' THEN B.[月中積数] ELSE 0 END) AS [一般定期通帳式月中積数]
    ,MAX(CASE WHEN B.[商品コード]='2060000000001' THEN B.[月中平残] ELSE 0 END) AS [一般定期通帳式月中平残]
    ,MAX(CASE WHEN B.[商品コード]='2060000000001' THEN B.[期中積数] ELSE 0 END) AS [一般定期通帳式期中積数]
    ,MAX(CASE WHEN B.[商品コード]='2060000000001' THEN B.[期中平残] ELSE 0 END) AS [一般定期通帳式期中平残]
    ,MAX(CASE WHEN B.[商品コード]='2060000000002' THEN B.[残高]     ELSE 0 END) AS [一般定期証書式残高]
    ,MAX(CASE WHEN B.[商品コード]='2060000000002' THEN B.[月中積数] ELSE 0 END) AS [一般定期証書式月中積数]
    ,MAX(CASE WHEN B.[商品コード]='2060000000002' THEN B.[月中平残] ELSE 0 END) AS [一般定期証書式月中平残]
    ,MAX(CASE WHEN B.[商品コード]='2060000000002' THEN B.[期中積数] ELSE 0 END) AS [一般定期証書式期中積数]
    ,MAX(CASE WHEN B.[商品コード]='2060000000002' THEN B.[期中平残] ELSE 0 END) AS [一般定期証書式期中平残]
    ,MAX(CASE WHEN B.[商品コード]='2010000000000' THEN B.[残高]     ELSE 0 END) AS [積立定期たむたむ残高]
    ,MAX(CASE WHEN B.[商品コード]='2010000000000' THEN B.[月中積数] ELSE 0 END) AS [積立定期たむたむ月中積数]
    ,MAX(CASE WHEN B.[商品コード]='2010000000000' THEN B.[月中平残] ELSE 0 END) AS [積立定期たむたむ月中平残]
    ,MAX(CASE WHEN B.[商品コード]='2010000000000' THEN B.[期中積数] ELSE 0 END) AS [積立定期たむたむ期中積数]
    ,MAX(CASE WHEN B.[商品コード]='2010000000000' THEN B.[期中平残] ELSE 0 END) AS [積立定期たむたむ期中平残]
    ,MAX(CASE WHEN B.[商品コード]='2030100000000' THEN B.[残高]     ELSE 0 END) AS [財形預金一般財形残高]
    ,MAX(CASE WHEN B.[商品コード]='2030100000000' THEN B.[月中積数] ELSE 0 END) AS [財形預金一般財形月中積数]
    ,MAX(CASE WHEN B.[商品コード]='2030100000000' THEN B.[月中平残] ELSE 0 END) AS [財形預金一般財形月中平残]
    ,MAX(CASE WHEN B.[商品コード]='2030100000000' THEN B.[期中積数] ELSE 0 END) AS [財形預金一般財形期中積数]
    ,MAX(CASE WHEN B.[商品コード]='2030100000000' THEN B.[期中平残] ELSE 0 END) AS [財形預金一般財形期中平残]
    ,MAX(CASE WHEN B.[商品コード]='2030200000000' THEN B.[残高]     ELSE 0 END) AS [財形預金年金財形残高]
    ,MAX(CASE WHEN B.[商品コード]='2030200000000' THEN B.[月中積数] ELSE 0 END) AS [財形預金年金財形月中積数]
    ,MAX(CASE WHEN B.[商品コード]='2030200000000' THEN B.[月中平残] ELSE 0 END) AS [財形預金年金財形月中平残]
    ,MAX(CASE WHEN B.[商品コード]='2030200000000' THEN B.[期中積数] ELSE 0 END) AS [財形預金年金財形期中積数]
    ,MAX(CASE WHEN B.[商品コード]='2030200000000' THEN B.[期中平残] ELSE 0 END) AS [財形預金年金財形期中平残]
    ,MAX(CASE WHEN B.[商品コード]='2030300000000' THEN B.[残高]     ELSE 0 END) AS [財形預金住宅財形残高]
    ,MAX(CASE WHEN B.[商品コード]='2030300000000' THEN B.[月中積数] ELSE 0 END) AS [財形預金住宅財形月中積数]
    ,MAX(CASE WHEN B.[商品コード]='2030300000000' THEN B.[月中平残] ELSE 0 END) AS [財形預金住宅財形月中平残]
    ,MAX(CASE WHEN B.[商品コード]='2030300000000' THEN B.[期中積数] ELSE 0 END) AS [財形預金住宅財形期中積数]
    ,MAX(CASE WHEN B.[商品コード]='2030300000000' THEN B.[期中平残] ELSE 0 END) AS [財形預金住宅財形期中平残]
    ,MAX(CASE WHEN B.[商品コード]='2020000000000' THEN B.[残高]     ELSE 0 END) AS [定期積金残高]
    ,MAX(CASE WHEN B.[商品コード]='2020000000000' THEN B.[月中積数] ELSE 0 END) AS [定期積金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='2020000000000' THEN B.[月中平残] ELSE 0 END) AS [定期積金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='2020000000000' THEN B.[期中積数] ELSE 0 END) AS [定期積金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='2020000000000' THEN B.[期中平残] ELSE 0 END) AS [定期積金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='ENKATEIKIYOKN' THEN B.[残高]     ELSE 0 END) AS [円貨定期性預金残高]
    ,MAX(CASE WHEN B.[商品コード]='ENKATEIKIYOKN' THEN B.[月中積数] ELSE 0 END) AS [円貨定期性預金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='ENKATEIKIYOKN' THEN B.[月中平残] ELSE 0 END) AS [円貨定期性預金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='ENKATEIKIYOKN' THEN B.[期中積数] ELSE 0 END) AS [円貨定期性預金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='ENKATEIKIYOKN' THEN B.[期中平残] ELSE 0 END) AS [円貨定期性預金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='3030000000001' THEN B.[残高]     ELSE 0 END) AS [スーパー定期残高]
    ,MAX(CASE WHEN B.[商品コード]='3030000000001' THEN B.[月中積数] ELSE 0 END) AS [スーパー定期月中積数]
    ,MAX(CASE WHEN B.[商品コード]='3030000000001' THEN B.[月中平残] ELSE 0 END) AS [スーパー定期月中平残]
    ,MAX(CASE WHEN B.[商品コード]='3030000000001' THEN B.[期中積数] ELSE 0 END) AS [スーパー定期期中積数]
    ,MAX(CASE WHEN B.[商品コード]='3030000000001' THEN B.[期中平残] ELSE 0 END) AS [スーパー定期期中平残]
    ,MAX(CASE WHEN B.[商品コード]='3030000000000' THEN B.[残高]     ELSE 0 END) AS [大口定期預金残高]
    ,MAX(CASE WHEN B.[商品コード]='3030000000000' THEN B.[月中積数] ELSE 0 END) AS [大口定期預金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='3030000000000' THEN B.[月中平残] ELSE 0 END) AS [大口定期預金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='3030000000000' THEN B.[期中積数] ELSE 0 END) AS [大口定期預金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='3030000000000' THEN B.[期中平残] ELSE 0 END) AS [大口定期預金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='ENKAYOKNGOKEI' THEN B.[残高]     ELSE 0 END) AS [円貨預金合計残高]
    ,MAX(CASE WHEN B.[商品コード]='ENKAYOKNGOKEI' THEN B.[月中積数] ELSE 0 END) AS [円貨預金合計月中積数]
    ,MAX(CASE WHEN B.[商品コード]='ENKAYOKNGOKEI' THEN B.[月中平残] ELSE 0 END) AS [円貨預金合計月中平残]
    ,MAX(CASE WHEN B.[商品コード]='ENKAYOKNGOKEI' THEN B.[期中積数] ELSE 0 END) AS [円貨預金合計期中積数]
    ,MAX(CASE WHEN B.[商品コード]='ENKAYOKNGOKEI' THEN B.[期中平残] ELSE 0 END) AS [円貨預金合計期中平残]
    ,MAX(CASE WHEN B.[商品コード]='3050100000000' THEN B.[残高]     ELSE 0 END) AS [外貨預金残高]
    ,MAX(CASE WHEN B.[商品コード]='3050100000000' THEN B.[月中積数] ELSE 0 END) AS [外貨預金月中積数]
    ,MAX(CASE WHEN B.[商品コード]='3050100000000' THEN B.[月中平残] ELSE 0 END) AS [外貨預金月中平残]
    ,MAX(CASE WHEN B.[商品コード]='3050100000000' THEN B.[期中積数] ELSE 0 END) AS [外貨預金期中積数]
    ,MAX(CASE WHEN B.[商品コード]='3050100000000' THEN B.[期中平残] ELSE 0 END) AS [外貨預金期中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZZZYOKINGOKEI' THEN B.[残高]     ELSE 0 END) AS [預金合計残高]
    ,MAX(CASE WHEN B.[商品コード]='ZZZYOKINGOKEI' THEN B.[月中積数] ELSE 0 END) AS [預金合計月中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZZZYOKINGOKEI' THEN B.[月中平残] ELSE 0 END) AS [預金合計月中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZZZYOKINGOKEI' THEN B.[期中積数] ELSE 0 END) AS [預金合計期中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZZZYOKINGOKEI' THEN B.[期中平残] ELSE 0 END) AS [預金合計期中平残]
    ,MAX(CASE WHEN B.[商品コード]='3040000000000' THEN B.[残高]     ELSE 0 END) AS [譲渡性預金ＮＣＤ残高]
    ,MAX(CASE WHEN B.[商品コード]='3040000000000' THEN B.[月中積数] ELSE 0 END) AS [譲渡性預金ＮＣＤ月中積数]
    ,MAX(CASE WHEN B.[商品コード]='3040000000000' THEN B.[月中平残] ELSE 0 END) AS [譲渡性預金ＮＣＤ月中平残]
    ,MAX(CASE WHEN B.[商品コード]='3040000000000' THEN B.[期中積数] ELSE 0 END) AS [譲渡性預金ＮＣＤ期中積数]
    ,MAX(CASE WHEN B.[商品コード]='3040000000000' THEN B.[期中平残] ELSE 0 END) AS [譲渡性預金ＮＣＤ期中平残]
FROM
(SELECT [作成基準日],[TBN],[CFB] FROM ${INFO_DB}.[T_KT10100D_OBJ]
 WHERE [作成基準日]=(SELECT [基準日] FROM ${INFO_DB}.[T_KT90085D_OBJ])) AS A
LEFT JOIN
(SELECT [店番],[ＣＩＦ番号],[科目],[商品コード]
       ,[残高],[月中積数],[月中平残],[期中積数],[期中平残]
 FROM ${INFO_DB}.[T_KT11070D_OBJ]) AS B
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
