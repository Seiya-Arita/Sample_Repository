#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :名寄せ入力データ			| T_NY02000D_OBJ
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :同一人名寄せ管理			| V_MA00030M_SRCB01
#                   :統合CIF基本情報			| T_MA00040M_SRC001
#                   :ＣＩＦ基本情報				| V_YK50060D_SRCB01
#                   :カナ住所S					| T_KT50210D_SRC001
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

INSERT INTO ${INFO_DB}.[T_NY02000D_OBJ]
SELECT
    H.[前日] AS [作成基準日],
    A.[店番],
    A.[ＣＩＦ番号],
    COALESCE(B.[統合ＣＩＦ番号],'') AS [統合ＣＩＦ番号],
    COALESCE(B.[代表ＣＩＦフラグ],'') AS [代表ＣＩＦフラグ],
    A.[生死表示],
    A.[漢字氏名],
    A.[カナ氏名],
    COALESCE(C.[名寄せ用カナ氏名],'') AS [名寄せ用カナ氏名],
    CASE WHEN A.[法人個人コード] = '01' AND (SUBSTRING(A.[業種コード],1,2) = '14' OR A.[業種コード] = '170100') THEN '1'
         WHEN A.[法人個人コード] = '01' AND SUBSTRING(A.[業種コード],1,2) <> '14' AND A.[業種コード] <> '170100' THEN '2'
         WHEN A.[法人個人コード] IN ('10','31','61') THEN '3'
         WHEN A.[法人個人コード] = '21' THEN '4'
         WHEN A.[法人個人コード] = '22' THEN '5'
         WHEN A.[法人個人コード] = '32' THEN '6'
         WHEN A.[法人個人コード] = '42' THEN '7'
         ELSE '8' END AS [法個人区分],
    A.[法人個人コード],
    A.[業種コード],
    A.[自宅電話番号] AS [電話番号],
    A.[住所コード],
    A.[漢字住所],
    COALESCE(D.[補助住所],'') AS [補助住所]
FROM ${INFO_DB}.[V_YK50060D_SRCB01] AS A
LEFT JOIN ${INFO_DB}.[V_MA00030D_SRCB01] AS B
    ON (A.[店番]=B.[店番] AND A.[ＣＩＦ番号]=B.[ＣＩＦ番号])
LEFT JOIN (
    SELECT
        E.[TWGCFB] AS [統合ＣＩＦ番号],
        E.[NYSYOOKSM] AS [名寄せ用カナ氏名]
    FROM ${DB_T_SRC}.[T_MA00040M_SRC001] AS E
    CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS H
    WHERE E.[Record_Deleted_Flag]=0
      AND CAST(CAST(H.[前日] AS CHAR(8)) AS DATE) BETWEEN E.[Start_Date] AND E.[End_Date]
) AS C
    ON (B.[統合ＣＩＦ番号]=C.[統合ＣＩＦ番号])
LEFT JOIN (
    SELECT
        F.[TBN] AS [店番],
        F.[CFB] AS [ＣＩＦ番号],
        (F.[KNATFMKTA] + F.[KNAKTA] + F.[KNAOAZTUOKTA] + F.[KNAAZMCMEKTA] + 1) AS [住所桁],
        TRIM(SUBSTRING(F.[KNAJUS], (F.[KNATFMKTA] + F.[KNAKTA] + F.[KNAOAZTUOKTA] + F.[KNAAZMCMEKTA] + 1), LEN(F.[KNAJUS]))) AS [補助住所]
    FROM ${DB_T_SRC}.[T_KT50210D_SRC001] AS F
    CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS H
    WHERE F.[Record_Deleted_Flag]=0
      AND CAST(CAST(H.[前日] AS CHAR(8)) AS DATE) BETWEEN F.[Start_Date] AND F.[End_Date]
) AS D
    ON (A.[店番]=D.[店番] AND A.[ＣＩＦ番号]=D.[ＣＩＦ番号])
CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD] AS H
WHERE A.[店番] BETWEEN 101 AND 400
  AND A.[生死表示] <> '1';
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
