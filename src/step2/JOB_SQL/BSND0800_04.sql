#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 追加テーブル名称  :                   | T_SN00801D_WK2
# フェーズ          :テーブル作成
# サイクル          :日次
# 実行日            :
# 参照テーブル      :                   | T_OM50020D_SRC001
#                                           ---> T_OM00230D_SRC001
# 参照テーブル      :                   | T_YK51010D_SRC001
# 参照テーブル      :                   | T_KT00060D_LOAD
#
# 備考              :ＦＧ証券用顧客口座情報作成
#
# 変更履歴
# -------------------------------------------------------------------------
# 2023-02-03        :新規作成           | KDS K.Setoguchi
# 2023-03-28        :抽出条件の変更     | KDS K.Setoguchi
# 2024-01-25        :下記を変更                              | KDS K.Sakata
#                      ・参照テーブル変更 (T_OM50020D_SRC001
#                                          ---> T_OM00230D_SRC001)
#                      ・参照テーブル変更に伴う抽出条件の変更
#
# =========================================================================
#
#  ＳＱＬ実行
#

sqlcmd -S ${SQL_SERVER} -d ${SQL_DB} -U ${SQL_USER} -P ${SQL_PASS} -f ${CHARSET} -t 0 -e -b -N o -Q "
DECLARE @ExitCode INT;
DECLARE @ErrorCode INT;
SET @ExitCode = 0;
SELECT GETDATE() AS DATE ;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ******************************************************/
/*  04_ＮＩＳＡ契約口座＿銀行契約取得 */
/* ******************************************************/
INSERT INTO ${INFO_DB}.T_SN00801D_WK2
/*--------------------  COMMENT START  ----------------------------2024-01-25*/
/*  SELECT
         A.[店番]                              AS  店番
        ,CASE WHEN B.[CFB] IS NULL
           THEN 0
           ELSE B.[CFB]
         END                                 AS  ＣＩＦ番号
        ,A.[科目]                              AS  科目
        ,A.[口座番号]                          AS  口座番号
    FROM
        ( SELECT
              CAST(SUBSTRING([TPOCOD],1,3) AS DECIMAL(3,0))   AS  店番
             ,CASE
                WHEN [YKF] = '1' THEN '12'
                WHEN [YKF] = '2' THEN '11'
                WHEN [YKF] = '3' THEN '16'
                WHEN [YKF] = '4' THEN '14'
                ELSE ''
              END                            AS  科目
             ,CAST([BNKKZB] AS DECIMAL(7,0))   AS  口座番号
         FROM  ${DB_T_SRC}.T_OM50020D_SRC001
         WHERE ( SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD ) BETWEEN [Start_Date] AND [End_Date]
           AND   [Record_Deleted_Flag] = 0
           AND   [TPOCOD] <> ''
/*         AND   [TKTKOZKBN]  in ('1','2') )  A  2023-03-28*/
           AND   [IVSKOZKBN] = '4'
           AND   [JUON1SKBN] = ''
           AND   [IVSKZTNCH] <> 0
           AND   [IVSKZPNCH] = 0 ) A
    LEFT JOIN
      ( SELECT * FROM ${DB_T_SRC}.T_YK51010D_SRC001
         WHERE ( SELECT CAST(CAST([前日] AS CHAR(8)) AS DATE) FROM ${INFO_DB}.T_KT00060D_LOAD ) BETWEEN [Start_Date] AND [End_Date]
           AND   [Record_Deleted_Flag] = 0
           AND   [SSSHYJ] = '' )  B
       ON  A.[店番] = B.[TBN]
       AND A.[科目] = B.[KMK]
       AND A.[口座番号] = B.[KZB]
    GROUP BY  A.[店番],B.[CFB],A.[科目],A.[口座番号]                                 */
/*--------------------  COMMENT END  ----------------------------------------*/
SELECT
     A.[HOSTBN]                            AS  店番
    ,A.[HOSCFB]                            AS  ＣＩＦ番号
    ,A.[HOSKMK]                            AS  科目
    ,A.[HOSKZB]                            AS  口座番号
FROM       ${DB_T_SRC}.T_OM00230D_SRC001  A
CROSS JOIN ${INFO_DB}.T_KT00060D_LOAD  B
  WHERE  CAST(CAST(B.[前日] AS CHAR(8)) AS DATE) BETWEEN A.[Start_Date] AND A.[End_Date]
    AND  A.[Record_Deleted_Flag] = 0
    AND  A.[DelKbn] = '0'
    AND  A.[Isa_Teki_Y] = SUBSTRING(CONVERT(VARCHAR, B.[前日]),1,4)
    AND  A.[HOSTBN] <> 0
    AND  A.[HOSCFB] <> 0
    AND  A.[HOSKMK] <> ''
    AND  A.[HOSKZB] <> 0
GROUP BY  A.[HOSTBN],A.[HOSCFB],A.[HOSKMK],A.[HOSKZB]
;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0 GOTO ENDPT;
/* ######################################################################### */
/*                               通常の退出処理                              */
/* ######################################################################### */
SELECT GETDATE() AS DATE ;
SET @ExitCode = 0;
GOTO Final;
/* ######################################################################### */
/*                           エラー発生時の退出処理                          */
/* ######################################################################### */
ENDPT:
SELECT GETDATE() AS DATE ;
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
