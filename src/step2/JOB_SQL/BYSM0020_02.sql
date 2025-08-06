#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 案件              :協19-123_貸倒実績率算定システムの導入
# 作成テーブル名称  :代位弁済情報作成                        T_YS00310M_OBJ
# フェーズ          :テーブル作成
# サイクル          :月次
# 実行日            :
# 変更履歴
# -------------------------------------------------------------------------
# 2021-01-18        :新規作成                                | SVC NAGATA
# =========================================================================
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
INSERT INTO ${INFO_DB}.[T_YS00310M_OBJ]
SELECT
    A.[作成基準日]                    AS [作成基準日],
    A.[店番]                          AS [店番],
    A.[ＣＩＦ番号]                    AS [ＣＩＦ番号],
    A.[科目]                          AS [科目],
    A.[取扱番号]                      AS [取扱番号],
    CASE WHEN A.[科目]='51'
         THEN CASE WHEN TRIM(ISNULL(B.[責任共有区分],' ')) IN ('1','9') THEN '1'
                                                                ELSE '3'
              END
         WHEN A.[科目]='52'
         THEN CASE WHEN TRIM(ISNULL(C.[責任共有区分],' ')) IN ('1','9') THEN '1'
                                                                ELSE '3'
              END
         WHEN A.[科目] IN ('53','54')
         THEN CASE WHEN TRIM(ISNULL(D.[責任共有区分],' ')) IN ('1','9') THEN '1'
                                                                ELSE '3'
              END
         WHEN A.[科目]='55'
         THEN CASE WHEN TRIM(ISNULL(E.[責任共有区分],' ')) IN ('1','9') THEN '1'
                                                                ELSE '3'
              END
         WHEN A.[科目]='56'
         THEN CASE WHEN TRIM(ISNULL(F.[責任共有区分],' ')) IN ('1','9') THEN '1'
                                                                ELSE '3'
              END
         WHEN A.[科目]='57'
         THEN CASE WHEN TRIM(ISNULL(G.[責任共有区分],' ')) IN ('1','9') THEN '1'
                                                                ELSE '3'
              END
         ELSE ' '
    END                             AS [債権区分],
    A.[代位弁済日]                    AS [代位弁済日],
    A.[代弁弁済額]                    AS [代弁弁済額],
    A.[うち元金]                      AS [うち元金],
    A.[うち利息]                      AS [うち利息],
    A.[倒産日]                        AS [倒産日],
    A.[倒産事由]                      AS [倒産事由],
    A.[提携区分]                      AS [提携区分],
    A.[保証機関コード]                AS [保証機関コード]
FROM (
    SELECT
        A3.[店番]                             AS [店番],
        A3.[ＣＩＦ番号]                       AS [ＣＩＦ番号],
        A3.[科目]                             AS [科目],
        A3.[取扱番号]                         AS [取扱番号],
        MAX(A3.[作成基準日])                  AS [作成基準日],
        MAX(A3.[代位弁済日])                  AS [代位弁済日],
        SUM(A3.[うち元金]) + SUM(A3.[うち利息]) AS [代弁弁済額],
        SUM(A3.[うち元金])                    AS [うち元金],
        SUM(A3.[うち利息])                    AS [うち利息],
        19001231                              AS [倒産日],
        ' '                                   AS [倒産事由],
        ' '                                   AS [提携区分],
        MAX([保証機関コード])                 AS [保証機関コード]
    FROM (
        SELECT
            A2.[前月末日]                                              AS [作成基準日],
            A1.[店番]                                                  AS [店番],
            A1.[ＣＩＦ番号]                                            AS [ＣＩＦ番号],
            A1.[科目]                                                  AS [科目],
            A1.[取扱番号]                                              AS [取扱番号],
            A1.[取扱勘定日]                                            AS [代位弁済日],
            CASE WHEN TRIM(A1.[バッチ用取引内訳Ｆ８]) IN ('1','2') THEN A1.[返済元金]*(-1)
                                                         ELSE A1.[返済元金]
            END                                                        AS [うち元金],
            CASE WHEN TRIM(A1.[バッチ用取引内訳Ｆ８]) IN ('1','2') THEN A1.[徴収利息]*(-1)
                                                         ELSE A1.[徴収利息]
            END                                                        AS [うち利息],
            A1.[担保区分]                                              AS [保証機関コード]
        FROM       ${INFO_DB}.[V_YS50030D_SRCB01] AS A1
        CROSS JOIN ${INFO_DB}.[T_KT00060D_LOAD]   AS A2
        WHERE A1.[付保証コード] <>'00' AND 
              A1.[回収区分] IN ( '08' , '98' , '05' , '95' , '90' ) AND 
              A1.[回収情報] IN ( '23' , '20' )                      AND
              A1.[取扱勘定日] BETWEEN A2.[前月月初日] AND A2.[前月末日]
        ) AS A3
    GROUP BY A3.[店番],A3.[ＣＩＦ番号],A3.[科目],A3.[取扱番号]
) AS A 
/* LDKA商手情報 */
LEFT JOIN (
    SELECT B1.[店番],B1.[ＣＩＦ番号],B1.[科目],B1.[取扱番号],B1.[作成基準日],B1.[責任共有区分]
    FROM ( 
        SELECT [店番],[ＣＩＦ番号],[科目],[取扱番号],[作成基準日],[責任共有区分],
               ROW_NUMBER() OVER(PARTITION BY [店番],[ＣＩＦ番号],[科目],[取扱番号] ORDER BY [作成基準日] DESC) ROWNO
        FROM ${INFO_DB}.[V_YS50060D_SRCB02] ) AS B1
    WHERE B1.ROWNO=1 ) AS B
ON A.[店番]       = B.[店番]       AND
   A.[ＣＩＦ番号] = B.[ＣＩＦ番号] AND
   A.[科目]       = B.[科目]       AND
   A.[取扱番号]   = B.[取扱番号]   AND
   A.[科目]       = '51'
/* LDKA手形貸付情報 */
LEFT JOIN (
    SELECT C1.[店番],C1.[ＣＩＦ番号],C1.[科目],C1.[取扱番号],C1.[作成基準日],C1.[責任共有区分]
    FROM ( 
        SELECT [店番],[ＣＩＦ番号],[科目],[取扱番号],[作成基準日],[責任共有区分],
               ROW_NUMBER() OVER(PARTITION BY [店番],[ＣＩＦ番号],[科目],[取扱番号] ORDER BY [作成基準日] DESC) ROWNO
        FROM ${INFO_DB}.[V_YS50070D_SRCB02] ) AS C1
    WHERE C1.ROWNO=1 ) AS C
ON A.[店番]       = C.[店番]       AND
   A.[ＣＩＦ番号] = C.[ＣＩＦ番号] AND
   A.[科目]       = C.[科目]       AND
   A.[取扱番号]   = C.[取扱番号]   AND
   A.[科目]       = '52'
/* LDKA証書貸付・ローン */
LEFT JOIN (
    SELECT D1.[店番],D1.[ＣＩＦ番号],D1.[科目],D1.[取扱番号],D1.[作成基準日],D1.[責任共有区分]
    FROM ( 
        SELECT [店番],[ＣＩＦ番号],[科目],[取扱番号],[作成基準日],[責任共有区分],
               ROW_NUMBER() OVER(PARTITION BY [店番],[ＣＩＦ番号],[科目],[取扱番号] ORDER BY [作成基準日] DESC) ROWNO
        FROM ${INFO_DB}.[V_YS50080D_SRCB02] ) AS D1
    WHERE D1.ROWNO=1 ) AS D
ON A.[店番]       = D.[店番]       AND
   A.[ＣＩＦ番号] = D.[ＣＩＦ番号] AND
   A.[科目]       = D.[科目]       AND
   A.[取扱番号]   = D.[取扱番号]   AND
   A.[科目]       IN('53','54')
/* LDKA支払承諾情報 */
LEFT JOIN (
    SELECT E1.[店番],E1.[ＣＩＦ番号],E1.[科目],E1.[取扱番号],E1.[作成基準日],E1.[責任共有区分]
    FROM ( 
        SELECT [店番],[ＣＩＦ番号],[科目],[取扱番号],[作成基準日],[責任共有区分],
               ROW_NUMBER() OVER(PARTITION BY [店番],[ＣＩＦ番号],[科目],[取扱番号] ORDER BY [作成基準日] DESC) ROWNO
        FROM ${INFO_DB}.[V_YS50090D_SRCB02] ) AS E1
    WHERE E1.ROWNO=1 ) AS E
ON A.[店番]       = E.[店番]       AND
   A.[ＣＩＦ番号] = E.[ＣＩＦ番号] AND
   A.[科目]       = E.[科目]       AND
   A.[取扱番号]   = E.[取扱番号]   AND
   A.[科目]       ='55'
/* LDKA代理貸付情報 */
LEFT JOIN (
    SELECT F1.[店番],F1.[ＣＩＦ番号],F1.[科目],F1.[取扱番号],F1.[作成基準日],F1.[責任共有区分]
    FROM ( 
        SELECT [店番],[ＣＩＦ番号],[科目],[取扱番号],[作成基準日],[責任共有区分],
               ROW_NUMBER() OVER(PARTITION BY [店番],[ＣＩＦ番号],[科目],[取扱番号] ORDER BY [作成基準日] DESC) ROWNO
        FROM ${INFO_DB}.[V_YS50100D_SRCB02] ) AS F1
    WHERE F1.ROWNO=1 ) AS F
ON A.[店番]       = F.[店番]       AND
   A.[ＣＩＦ番号] = F.[ＣＩＦ番号] AND
   A.[科目]       = F.[科目]       AND
   A.[取扱番号]   = F.[取扱番号]   AND
   A.[科目]       ='56'
/* LDKA融資当貸情報 */
LEFT JOIN (
    SELECT G1.[店番],G1.[ＣＩＦ番号],G1.[科目],G1.[取扱番号],G1.[作成基準日],G1.[責任共有区分]
    FROM ( 
        SELECT [店番],[ＣＩＦ番号],[科目],[取扱番号],[作成基準日],[責任共有区分],
               ROW_NUMBER() OVER(PARTITION BY [店番],[ＣＩＦ番号],[科目],[取扱番号] ORDER BY [作成基準日] DESC) ROWNO
        FROM ${INFO_DB}.[V_YS50110D_SRCB02] ) AS G1
    WHERE G1.ROWNO=1 ) AS G
ON A.[店番]       = G.[店番]       AND
   A.[ＣＩＦ番号] = G.[ＣＩＦ番号] AND
   A.[科目]       = G.[科目]       AND
   A.[取扱番号]   = G.[取扱番号]   AND
   A.[科目]       ='57'
WHERE  A.[代弁弁済額] > 0
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
