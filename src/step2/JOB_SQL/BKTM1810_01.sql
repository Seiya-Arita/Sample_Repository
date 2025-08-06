#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :ＣＩＦ動態情報店ＣＩＦ単位（SCOPE） | T_KT18100D_OBJ
# フェーズ          :テーブル作成
# サイクル          :月次
# 参照テーブル      :預金ＣＩＦ基本Ｓ               | T_YK50060D_SRC001
#                   :ＣＩＦ動態情報縦持ち           | T_KT18050D_OBJ
#                   :日付テーブル                   | T_KT00060D_LOAD
#
# 変更履歴
# -------------------------------------------------------------------------
# 2024-10-21        :新規作成                       | K.Setoguchi
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
INSERT INTO ${INFO_DB}.T_KT18100M_OBJ
SELECT
     C.[前月末日]                                                  AS [作成基準日]
    ,C.[店番]                                                      AS [店番]
    ,C.[ＣＩＦ番号]                                                AS [ＣＩＦ番号]
    ,MAX(CASE WHEN D.[項目コード]='1001' THEN D.[金額]   ELSE 0 END) AS [入金金額]
    ,MAX(CASE WHEN D.[項目コード]='1002' THEN D.[金額]   ELSE 0 END) AS [支払金額]
    ,MAX(CASE WHEN D.[項目コード]='2001' THEN D.[件数]   ELSE 0 END) AS [ＡＴＭ入金件数]
    ,MAX(CASE WHEN D.[項目コード]='2002' THEN D.[金額]   ELSE 0 END) AS [ＡＴＭ入金金額]
    ,MAX(CASE WHEN D.[項目コード]='2003' THEN D.[件数]   ELSE 0 END) AS [ＡＴＭ支払件数]
    ,MAX(CASE WHEN D.[項目コード]='2004' THEN D.[金額]   ELSE 0 END) AS [ＡＴＭ支払金額]
    ,MAX(CASE WHEN D.[項目コード]='2005' THEN D.[件数]   ELSE 0 END) AS [ＡＴＭ振込件数]
    ,MAX(CASE WHEN D.[項目コード]='2006' THEN D.[金額]   ELSE 0 END) AS [ＡＴＭ振込金額]
    ,0                                                           AS [ＡＴＭ残高照会件数]
    ,MAX(CASE WHEN D.[項目コード]='3001' THEN D.[金額]   ELSE 0 END) AS [自振月間振替額＿実績]
    ,MAX(CASE WHEN D.[項目コード]='3002' THEN D.[金額]   ELSE 0 END) AS [給振合計＿金額]
    ,MAX(CASE WHEN D.[項目コード]='3003' THEN D.[金額]   ELSE 0 END) AS [年金入金合計＿金額]
    ,MAX(CASE WHEN D.[項目コード]='3004' THEN D.[金額]   ELSE 0 END) AS [電話料金＿金額]
    ,MAX(CASE WHEN D.[項目コード]='3005' THEN D.[金額]   ELSE 0 END) AS [電気料金＿金額]
    ,MAX(CASE WHEN D.[項目コード]='3006' THEN D.[金額]   ELSE 0 END) AS [ガス＿金額]
    ,MAX(CASE WHEN D.[項目コード]='3007' THEN D.[金額]   ELSE 0 END) AS [水道＿金額]
    ,MAX(CASE WHEN D.[項目コード]='3008' THEN D.[金額]   ELSE 0 END) AS [ＮＨＫ＿金額]
    ,MAX(CASE WHEN D.[項目コード]='3009' THEN D.[金額]   ELSE 0 END) AS [ＢＣカード自振額]
    ,MAX(CASE WHEN D.[項目コード]='3010' THEN D.[金額]   ELSE 0 END) AS [肥銀ＪＣＢワールドＣＤ自振]
    ,MAX(CASE WHEN D.[項目コード]='4001' THEN D.[件数]   ELSE 0 END) AS [他銀行系クレジット＿件数]
    ,MAX(CASE WHEN D.[項目コード]='4002' THEN D.[金額]   ELSE 0 END) AS [他銀行系クレジット＿金額]
    ,MAX(CASE WHEN D.[項目コード]='4003' THEN D.[件数]   ELSE 0 END) AS [信販系クレジット＿件数]
    ,MAX(CASE WHEN D.[項目コード]='4004' THEN D.[金額]   ELSE 0 END) AS [信販系クレジット＿金額]
    ,MAX(CASE WHEN D.[項目コード]='4005' THEN D.[件数]   ELSE 0 END) AS [流通系クレジット＿件数]
    ,MAX(CASE WHEN D.[項目コード]='4006' THEN D.[金額]   ELSE 0 END) AS [流通系クレジット＿金額]
    ,MAX(CASE WHEN D.[項目コード]='4007' THEN D.[件数]   ELSE 0 END) AS [メーカー系クレジット＿件数]
    ,MAX(CASE WHEN D.[項目コード]='4008' THEN D.[金額]   ELSE 0 END) AS [メーカー系クレジット＿金額]
    ,MAX(CASE WHEN D.[項目コード]='4009' THEN D.[件数]   ELSE 0 END) AS [その他クレジット＿件数]
    ,MAX(CASE WHEN D.[項目コード]='4010' THEN D.[金額]   ELSE 0 END) AS [その他クレジット＿金額]
    ,CASE WHEN MAX(CASE WHEN D.[項目コード]='4004' THEN D.[金額]   ELSE 0 END) > 0
       THEN 1
       ELSE 0
     END                                                         AS [自動支払＿信販系ＣＲ]
FROM (
      SELECT
          [前月末日]                                               AS [前月末日]
         ,[TBN]                                                    AS [店番]
         ,[CFB]                                                    AS [ＣＩＦ番号]
      FROM ${DB_T_SRC}.T_YK50060D_SRC001 AS A                           /* 預金ＣＩＦ基本Ｓ */
      CROSS JOIN  ${INFO_DB}.T_KT00060D_LOAD AS B                       /* 日付テーブル */
         WHERE  CAST(CAST(B.[前月末日] AS CHAR(8)) AS DATE) BETWEEN A.[Start_Date] AND A.[End_Date]
           AND  A.[Record_Deleted_Flag] = 0                               /*ＧＣＦＲ削除フラグ*/
           AND  A.[SSSHYJ]=''                                             /*生死表示*/
     ) AS C
LEFT JOIN  ${INFO_DB}.T_KT18050M_OBJ AS D
    ON  C.[前月末日] = D.[作成基準日]
   AND  C.[店番] = D.[店番]
   AND  C.[ＣＩＦ番号] = D.[ＣＩＦ番号]
GROUP BY  C.[前月末日],C.[店番],C.[ＣＩＦ番号];
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
