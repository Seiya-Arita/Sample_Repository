#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :【CC】顧客商品契約有無情報                | T_SN30100D_WK7
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :ＡＰＩ操作履歴                            | V_SN40030D_SRCB01
#                   :ＡＰＩ利用者                              | V_SN40010D_SRCB01
#                   :ＡＰＩ商品契約有無（累積）                | T_SN30100D_API
#                   :顧客商品有無コード変換                    | T_SN30150Z_OBJ
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2021-08-23        :新規作成                                  | SVC TSUKINOKI
# 2023-01-23        :商品コード変換処理変更(直指定→マスタ)    | KODAMA
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
/* 【CC】顧客商品有無情報作成（商品追加＿機能サービス） */
/*  ＡＰＩ各アプリ */
/* ****************************************************************** */

/* ******************************** */
/* 前日データ取得  */
/* ******************************** */

INSERT INTO ${INFO_DB}.T_SN30100D_APIWK1
    /* APIサービス利用者の店CIFを抽出 */
    SELECT
        CAST(CONVERT(VARCHAR(8), T1.[Start_Date], 112) AS DECIMAL(8)) AS [作成基準日],
        T2.[TBN] AS [店番],
        T2.[CFB] AS [ＣＩＦ番号],
        '' AS [統合ＣＩＦ番号],
        T3.[商品コード] AS [商品コード]
    FROM
    (
        SELECT
            [Start_Date],
            [認証ＩＤ],
            [クライアントＩＤ]
        FROM ${INFO_DB}.V_SN40030D_SRCB01
        WHERE
        /* 累積データの作成基準日と比較し差分の履歴を抽出する */
        CAST(CONVERT(VARCHAR(8), [Start_Date], 112) AS DECIMAL(8))
            > (SELECT ISNULL(MAX([作成基準日]),0) FROM ${INFO_DB}.T_SN30100D_API)
    ) AS T1

    INNER JOIN
    (
        SELECT
            [Start_Date],
            [End_Date],
            [NSNIDE],
            [TBN],
            [CFB]
        FROM ${INFO_DB}.V_SN40010D_SRCB01
    ) AS T2
    /* 操作履歴と同一断面の利用者を抽出する */
    ON  T1.[認証ＩＤ]=T2.[TBN]
    AND (T1.[Start_Date] BETWEEN T2.[Start_Date] AND T2.[End_Date])

    INNER JOIN
    (
        SELECT
            [変換前コード],
            [商品コード]
        FROM ${INFO_DB}.T_SN30150Z_OBJ
        WHERE [種別] = '01'
    ) AS T3
    ON  T1.[クライアントＩＤ]=T3.[変換前コード]

    GROUP BY CAST(CONVERT(VARCHAR(8), T1.[Start_Date], 112) AS DECIMAL(8)), T2.[TBN], T2.[CFB], T3.[商品コード]
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
