#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :名寄せフォーマット変換		| T_NY04000D_OBJ	
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :名寄せ入力抽出個人			| T_NY02100D_OBJ
#
# 変更履歴
# -------------------------------------------------------------------------
# 2022-03-31        :新規作成                   | Shunya.M
# =========================================================================
#
#  ＳＱＬ実行
#

sqlcmd -S ${SQL_SERVER} -d ${SQL_DB} -U ${SQL_USER} -P ${SQL_PASS} -f ${CHARSET} -t 0 -e -w 300 -b -N o -Q "
DECLARE @ExitCode INT;
DECLARE @ErrorCode INT;
SET @ExitCode = 0;
SELECT GETDATE() AS [DATE];
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
INSERT INTO ${INFO_DB}.T_NY04000D_OBJ
SELECT
    A.[作成基準日],
    A.[店番],
    A.[ＣＩＦ番号],
    A.[統合ＣＩＦ番号],
    A.[代表ＣＩＦフラグ],
    A.[生死表示],
    A.[漢字氏名],
    A.[カナ氏名],
    A.[名寄せ用カナ氏名],
    A.[電話番号],
    A.[住所コード],
    A.[補助住所],
    CASE WHEN CHARINDEX(' ',A.[カナ氏名]) > 0
         THEN SUBSTRING(A.[カナ氏名],1,CHARINDEX(' ',A.[カナ氏名]) -1)
         ELSE A.[カナ氏名]
    END AS [カナ氏名＿Ｎ],
    CASE WHEN CHARINDEX(' ',A.[名寄せ用カナ氏名]) > 0
         THEN SUBSTRING(A.[名寄せ用カナ氏名],1,CHARINDEX(' ',A.[名寄せ用カナ氏名]) -1)
         ELSE A.[名寄せ用カナ氏名]
    END AS [名寄せ用カナ氏名＿Ｎ],
    REPLACE(A.[電話番号],'-','') AS [電話番号＿Ｎ],
    LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(B.[補助住所],
    '------','-'),
    '-----','-'),
    '----','-'),
    '---','-'),
    '--','-'))) AS [補助住所＿Ｎ]
FROM ${INFO_DB}.T_NY02100D_OBJ AS A
INNER JOIN (
    SELECT
        [統合ＣＩＦ番号],
        dbo.Otranslate(dbo.Otranslate([補助住所],
        'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝﾞﾟ',
        '------------------------------------------------'),
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ ｰ().&',
        '--------------------------------') AS [補助住所]
    FROM ${INFO_DB}.T_NY02100D_OBJ
    WHERE [代表ＣＩＦフラグ] = '1'
) AS B
ON (A.[統合ＣＩＦ番号] = B.[統合ＣＩＦ番号])
WHERE A.[代表ＣＩＦフラグ] = '1';
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
