#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :名寄せインデックス作成		| T_NY08000D_OBJ	
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :名寄せ入力データ			| T_NY02000D_OBJ
#                   :確定世帯番号				| T_NY07000D_OBJ
#                   :【管理店】管理店情報_バッチ| T_KT15500D_OBJ
#
# 変更履歴
# -------------------------------------------------------------------------
# 2022-03-31        :新規作成                           | Shunya.M
# 2024-11-11        :協24-122_統合CIFベース業務態勢整備 | Shunya.M
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
INSERT INTO ${INFO_DB}.T_NY08000D_OBJ
SELECT
    A.[作成基準日],
    A.[店番],
    A.[ＣＩＦ番号],
    A.[統合ＣＩＦ番号],
    A.[代表ＣＩＦフラグ],
    ISNULL(B.[世帯番号],0) AS [世帯番号],
    CASE WHEN A.[店番] = B.[店番] AND A.[ＣＩＦ番号] = B.[ＣＩＦ番号]
         THEN B.[世帯代表フラグ]
         ELSE ''
    END AS [世帯代表フラグ],
    ISNULL(E.[管理店番],A.[店番]) AS [管理店番],
    ISNULL(C.[保有ＣＩＦ数],0) AS [保有ＣＩＦ数],
    ISNULL(C.[取引店舗数],0) AS [取引店舗数],
    ISNULL(D.[保有ＣＩＦ数],0) AS [世帯保有ＣＩＦ数],
    ISNULL(D.[取引店舗数],0) AS [世帯取引店舗数],
    A.[生死表示],
    A.[漢字氏名],
    A.[カナ氏名],
    A.[名寄せ用カナ氏名],
    A.[法個人区分],
    A.[法人個人コード],
    A.[業種コード],
    A.[電話番号],
    A.[住所コード],
    A.[漢字住所],
    A.[補助住所]
FROM ${INFO_DB}.T_NY02000D_OBJ AS A
LEFT JOIN ${INFO_DB}.T_NY07000D_OBJ AS B
    ON (A.[統合ＣＩＦ番号]=B.[統合ＣＩＦ番号])
LEFT JOIN (
    SELECT
        [統合ＣＩＦ番号],
        COUNT(*) AS [保有ＣＩＦ数],
        COUNT(DISTINCT([店番])) AS [取引店舗数]
    FROM ${INFO_DB}.T_NY02000D_OBJ
    GROUP BY [統合ＣＩＦ番号]
) AS C
    ON (A.[統合ＣＩＦ番号]=C.[統合ＣＩＦ番号])
LEFT JOIN (
    SELECT
        F.[世帯番号],
        COUNT(*) AS [保有ＣＩＦ数],
        COUNT(DISTINCT(E.[店番])) AS [取引店舗数]
    FROM ${INFO_DB}.T_NY02000D_OBJ AS E
    INNER JOIN ${INFO_DB}.T_NY07000D_OBJ AS F
        ON (E.[統合ＣＩＦ番号]=F.[統合ＣＩＦ番号])
    GROUP BY F.[世帯番号]
) AS D
    ON (B.[世帯番号]=D.[世帯番号])
LEFT JOIN ${INFO_DB}.T_KT15500D_OBJ AS E
    ON (A.[店番] = E.[店番]
        AND A.[ＣＩＦ番号] = E.[ＣＩＦ番号])
;
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
