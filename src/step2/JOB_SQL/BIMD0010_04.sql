#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# =========================================================================
# 作成テーブル名称  :口座情報					| T_IM00010D_OBJ

# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :ＣＩＦワーク					| T_IM00011D_WK
#                   :融資明細	 					| V_KT30020D_SRCB01
#
# 変更履歴
# -------------------------------------------------------------------------
# 2021-10-15        :新規作成                       | ：meistier KIHARA
# 2023-02-01        :暫定重複対応                   | ：meistier KIHARA
# 2024-09-30        :暫定重複対応                   | ：meistier KIHARA
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
INSERT INTO ${INFO_DB}.T_IM00010D_OBJ
SELECT B.[作成基準日],
       A.[店番],
       A.[科目],
       A.[取扱番号] AS [口座番号],
       MAX(A.[ＣＩＦ番号]) AS [店別顧客番号],
       B.[顧客番号],
       B.[カナ氏名],
       B.[漢字氏名],
       B.[生年月日]
FROM ${INFO_DB}.V_KT30020D_SRCB01 AS A
INNER JOIN ${INFO_DB}.T_IM00011D_WK AS B
  ON (A.[店番] = B.[店番])
  AND (A.[ＣＩＦ番号] = B.[ＣＩＦ番号])
WHERE A.[科目] NOT IN('11','12') AND
NOT ((A.[取扱番号]=800017 AND A.[科目]='51' AND A.[店番]=253) OR
     (A.[取扱番号]=800002 AND A.[科目]='51' AND A.[店番]=169) OR
     (A.[取扱番号]=809643 AND A.[科目]='51' AND A.[店番]=101) OR
     (A.[取扱番号]=800175 AND A.[科目]='51' AND A.[店番]=282))
GROUP BY B.[作成基準日],A.[店番],A.[科目],A.[取扱番号],B.[顧客番号],B.[カナ氏名],B.[漢字氏名],B.[生年月日];
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
