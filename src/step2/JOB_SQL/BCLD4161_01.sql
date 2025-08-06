#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :通知ファイル                      | /work/tmp/BCLD4161.txt
# フェーズ          :テーブル作成
# サイクル          :日次
# 参照テーブル      :業務支援系商品マスタ（通知対象）          | T_KT41000D_WKZ
#
#
# 変更履歴
# ------------------------------------------------------------------------------
# 2021-08-30        :新規作成                                  | SVC TSUKINOKI
# ===============================================================================

#通知ファイル
EXP_FILE_NAME=/work/tmp/BCLD4161.txt
#通知ファイル削除
rm -f ${EXP_FILE_NAME}

#
#  ＳＱＬ実行
#

sqlcmd -S ${SQL_SERVER} -d ${SQL_DB} -U ${SQL_USER} -P ${SQL_PASS} -f ${CHARSET} -t 0 -e -w 254 -b -N o -Q "
DECLARE @ExitCode INT;
DECLARE @ErrorCode INT;
SET @ExitCode = 0;
/* .EXPORT REPORT NOBOM FILE=${EXP_FILE_NAME} */
/* .SET SEPARATOR ","; */
/* .SET TITLEDASHES OFF; */
SELECT
    TRIM([商品コード]) AS [商品コード],
    TRIM([商品名称]) AS [商品名称],
    TRIM([登録種別]) AS [登録種別],
    TRIM([削除フラグ]) AS [削除フラグ],
    TRIM([備考]) AS [備考]
FROM
(
    SELECT
        [商品コード],
        [商品名称],
        [登録種別],
        [削除フラグ],
        [備考]
    FROM ${INFO_DB}.T_KT41000D_OBJ
    WHERE [更新日] = (SELECT [前日] FROM ${INFO_DB}.T_KT00060D_LOAD)
    UNION ALL
    SELECT
        [商品コード],
        [商品名称],
        [登録種別],
        [削除フラグ],
        '外部入力／自動採番でのコード重複' AS [備考]
    FROM ${INFO_DB}.T_KT41000D_WK92
    WHERE [商品コード] IN (SELECT [商品コード] FROM ${INFO_DB}.T_KT41000D_OBJ WHERE [登録種別] <> '1')
) AS Z;
SELECT @ErrorCode = @@ERROR;
IF @ErrorCode <> 0
BEGIN
  SET @ExitCode = 8;
  GOTO Final;
END
/* ######################################################################### */
/*                    処理を終了し、終了コードを返却する                       */
/* ######################################################################### */
Final:
:EXIT(SELECT @ExitCode)
"


#
exit $?
