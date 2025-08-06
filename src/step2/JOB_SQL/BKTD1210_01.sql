#!/bin/sh
. "/home/ec2-user/kyo/logger.sh"

# スクリプト自身のパスを取得（bashでも.でも動く）
script_path="$(realpath "${BASH_SOURCE[0]:-${0}}")"

log_exec "$script_path" "$@"

# ==============================================================================
# 作成テーブル名称  :ＣＩＦ残高融資                            | HN_INFO.T_KT12070D
# フェーズ          :ＣＩＦ残高
# サイクル          :日次
# 参照テーブル      :融資計数集約                              | HN_INFO.T_KT12070D_OBJ
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
/* ＣＩＦ残高融資 */
/* ****************************************************************** */
INSERT INTO ${INFO_DB}.[T_KT12100D_OBJ]
SELECT
     A.[作成基準日] AS [作成基準日]
    ,A.[TBN] AS [店番]
    ,A.[CFB] AS [ＣＩＦ番号]
    ,MAX(CASE WHEN B.[商品コード]='4090000000000' THEN B.[残高]     ELSE 0 END) AS [商業手形残高]
    ,MAX(CASE WHEN B.[商品コード]='4090000000000' THEN B.[月中積数] ELSE 0 END) AS [商業手形月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4090000000000' THEN B.[月中平残] ELSE 0 END) AS [商業手形月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4090000000000' THEN B.[期中積数] ELSE 0 END) AS [商業手形期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4090000000000' THEN B.[期中平残] ELSE 0 END) AS [商業手形期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4100000000000' THEN B.[残高]     ELSE 0 END) AS [手形貸付残高]
    ,MAX(CASE WHEN B.[商品コード]='4100000000000' THEN B.[月中積数] ELSE 0 END) AS [手形貸付月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4100000000000' THEN B.[月中平残] ELSE 0 END) AS [手形貸付月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4100000000000' THEN B.[期中積数] ELSE 0 END) AS [手形貸付期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4100000000000' THEN B.[期中平残] ELSE 0 END) AS [手形貸付期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4140000000000' THEN B.[残高]     ELSE 0 END) AS [証書貸付残高]
    ,MAX(CASE WHEN B.[商品コード]='4140000000000' THEN B.[月中積数] ELSE 0 END) AS [証書貸付月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4140000000000' THEN B.[月中平残] ELSE 0 END) AS [証書貸付月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4140000000000' THEN B.[期中積数] ELSE 0 END) AS [証書貸付期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4140000000000' THEN B.[期中平残] ELSE 0 END) AS [証書貸付期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4110000000000' THEN B.[残高]     ELSE 0 END) AS [融資当貸残高]
    ,MAX(CASE WHEN B.[商品コード]='4110000000000' THEN B.[月中積数] ELSE 0 END) AS [融資当貸月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4110000000000' THEN B.[月中平残] ELSE 0 END) AS [融資当貸月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4110000000000' THEN B.[期中積数] ELSE 0 END) AS [融資当貸期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4110000000000' THEN B.[期中平残] ELSE 0 END) AS [融資当貸期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4120000000000' THEN B.[残高]     ELSE 0 END) AS [預金当貸残高]
    ,MAX(CASE WHEN B.[商品コード]='4120000000000' THEN B.[月中積数] ELSE 0 END) AS [預金当貸月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4120000000000' THEN B.[月中平残] ELSE 0 END) AS [預金当貸月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4120000000000' THEN B.[期中積数] ELSE 0 END) AS [預金当貸期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4120000000000' THEN B.[期中平残] ELSE 0 END) AS [預金当貸期中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZG-KASHIDASHI' THEN B.[残高]     ELSE 0 END) AS [外貨貸出残高]
    ,MAX(CASE WHEN B.[商品コード]='ZG-KASHIDASHI' THEN B.[月中積数] ELSE 0 END) AS [外貨貸出月中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZG-KASHIDASHI' THEN B.[月中平残] ELSE 0 END) AS [外貨貸出月中平残]
    ,MAX(CASE WHEN B.[商品コード]='ZG-KASHIDASHI' THEN B.[期中積数] ELSE 0 END) AS [外貨貸出期中積数]
    ,MAX(CASE WHEN B.[商品コード]='ZG-KASHIDASHI' THEN B.[期中平残] ELSE 0 END) AS [外貨貸出期中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZ0000000009' THEN B.[残高]     ELSE 0 END) AS [ローン残高]
    ,MAX(CASE WHEN B.[商品コード]='AZZ0000000009' THEN B.[月中積数] ELSE 0 END) AS [ローン月中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZ0000000009' THEN B.[月中平残] ELSE 0 END) AS [ローン月中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZ0000000009' THEN B.[期中積数] ELSE 0 END) AS [ローン期中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZ0000000009' THEN B.[期中平残] ELSE 0 END) AS [ローン期中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZ0000000010' THEN B.[残高]     ELSE 0 END) AS [貸出合計残高]
    ,MAX(CASE WHEN B.[商品コード]='AZZ0000000010' THEN B.[月中積数] ELSE 0 END) AS [貸出合計月中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZ0000000010' THEN B.[月中平残] ELSE 0 END) AS [貸出合計月中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZ0000000010' THEN B.[期中積数] ELSE 0 END) AS [貸出合計期中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZ0000000010' THEN B.[期中平残] ELSE 0 END) AS [貸出合計期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4080000000000' THEN B.[残高]     ELSE 0 END) AS [事業資金貸出残高]
    ,MAX(CASE WHEN B.[商品コード]='4080000000000' THEN B.[月中積数] ELSE 0 END) AS [事業資金貸出月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4080000000000' THEN B.[月中平残] ELSE 0 END) AS [事業資金貸出月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4080000000000' THEN B.[期中積数] ELSE 0 END) AS [事業資金貸出期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4080000000000' THEN B.[期中平残] ELSE 0 END) AS [事業資金貸出期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4080000000000' THEN B.[当初貸出日] ELSE 0 END) AS [事業資金貸出当初貸出日]
    ,MAX(CASE WHEN B.[商品コード]='4190000000000' THEN B.[残高]     ELSE 0 END) AS [事業資金貸出保証付残高]
    ,MAX(CASE WHEN B.[商品コード]='4190000000000' THEN B.[月中積数] ELSE 0 END) AS [事業資金貸出保証付月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4190000000000' THEN B.[月中平残] ELSE 0 END) AS [事業資金貸出保証付月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4190000000000' THEN B.[期中積数] ELSE 0 END) AS [事業資金貸出保証付期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4190000000000' THEN B.[期中平残] ELSE 0 END) AS [事業資金貸出保証付期中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0023' THEN B.[残高]     ELSE 0 END) AS [スプレッド貸出残高]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0023' THEN B.[月中積数] ELSE 0 END) AS [スプレッド貸出月中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0023' THEN B.[月中平残] ELSE 0 END) AS [スプレッド貸出月中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0023' THEN B.[期中積数] ELSE 0 END) AS [スプレッド貸出期中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0023' THEN B.[期中平残] ELSE 0 END) AS [スプレッド貸出期中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0024' THEN B.[残高]     ELSE 0 END) AS [個人ローン合計残高]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0024' THEN B.[月中積数] ELSE 0 END) AS [個人ローン合計月中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0024' THEN B.[月中平残] ELSE 0 END) AS [個人ローン合計月中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0024' THEN B.[期中積数] ELSE 0 END) AS [個人ローン合計期中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0024' THEN B.[期中平残] ELSE 0 END) AS [個人ローン合計期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4010000000000' THEN B.[残高]     ELSE 0 END) AS [カードローン残高]
    ,MAX(CASE WHEN B.[商品コード]='4010000000000' THEN B.[月中積数] ELSE 0 END) AS [カードローン月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4010000000000' THEN B.[月中平残] ELSE 0 END) AS [カードローン月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4010000000000' THEN B.[期中積数] ELSE 0 END) AS [カードローン期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4010000000000' THEN B.[期中平残] ELSE 0 END) AS [カードローン期中平残]
    ,MAX(CASE WHEN B.[商品コード]='A010000000000' THEN B.[残高]     ELSE 0 END) AS [住宅ローン残高]
    ,MAX(CASE WHEN B.[商品コード]='A010000000000' THEN B.[月中積数] ELSE 0 END) AS [住宅ローン月中積数]
    ,MAX(CASE WHEN B.[商品コード]='A010000000000' THEN B.[月中平残] ELSE 0 END) AS [住宅ローン月中平残]
    ,MAX(CASE WHEN B.[商品コード]='A010000000000' THEN B.[期中積数] ELSE 0 END) AS [住宅ローン期中積数]
    ,MAX(CASE WHEN B.[商品コード]='A010000000000' THEN B.[期中平残] ELSE 0 END) AS [住宅ローン期中平残]
    ,MAX(CASE WHEN B.[商品コード]='A010000000000' THEN B.[当初貸出日] ELSE 0 END) AS [住宅ローン当初貸出日]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0027' THEN B.[残高]     ELSE 0 END) AS [アパートローン残高]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0027' THEN B.[月中積数] ELSE 0 END) AS [アパートローン月中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0027' THEN B.[月中平残] ELSE 0 END) AS [アパートローン月中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0027' THEN B.[期中積数] ELSE 0 END) AS [アパートローン期中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0027' THEN B.[期中平残] ELSE 0 END) AS [アパートローン期中平残]
    ,MAX(CASE WHEN B.[商品コード]='A050000000000' THEN B.[残高]     ELSE 0 END) AS [フリーローン残高]
    ,MAX(CASE WHEN B.[商品コード]='A050000000000' THEN B.[月中積数] ELSE 0 END) AS [フリーローン月中積数]
    ,MAX(CASE WHEN B.[商品コード]='A050000000000' THEN B.[月中平残] ELSE 0 END) AS [フリーローン月中平残]
    ,MAX(CASE WHEN B.[商品コード]='A050000000000' THEN B.[期中積数] ELSE 0 END) AS [フリーローン期中積数]
    ,MAX(CASE WHEN B.[商品コード]='A050000000000' THEN B.[期中平残] ELSE 0 END) AS [フリーローン期中平残]
    ,MAX(CASE WHEN B.[商品コード]='A030100000000' THEN B.[残高]     ELSE 0 END) AS [マイカーローン残高]
    ,MAX(CASE WHEN B.[商品コード]='A030100000000' THEN B.[月中積数] ELSE 0 END) AS [マイカーローン月中積数]
    ,MAX(CASE WHEN B.[商品コード]='A030100000000' THEN B.[月中平残] ELSE 0 END) AS [マイカーローン月中平残]
    ,MAX(CASE WHEN B.[商品コード]='A030100000000' THEN B.[期中積数] ELSE 0 END) AS [マイカーローン期中積数]
    ,MAX(CASE WHEN B.[商品コード]='A030100000000' THEN B.[期中平残] ELSE 0 END) AS [マイカーローン期中平残]
    ,MAX(CASE WHEN B.[商品コード]='A040000000000' THEN B.[残高]     ELSE 0 END) AS [教育ローン残高]
    ,MAX(CASE WHEN B.[商品コード]='A040000000000' THEN B.[月中積数] ELSE 0 END) AS [教育ローン月中積数]
    ,MAX(CASE WHEN B.[商品コード]='A040000000000' THEN B.[月中平残] ELSE 0 END) AS [教育ローン月中平残]
    ,MAX(CASE WHEN B.[商品コード]='A040000000000' THEN B.[期中積数] ELSE 0 END) AS [教育ローン期中積数]
    ,MAX(CASE WHEN B.[商品コード]='A040000000000' THEN B.[期中平残] ELSE 0 END) AS [教育ローン期中平残]
    ,MAX(CASE WHEN B.[商品コード]='A109900000000' THEN B.[残高]     ELSE 0 END) AS [その他当行借入ローン残高]
    ,MAX(CASE WHEN B.[商品コード]='A109900000000' THEN B.[月中積数] ELSE 0 END) AS [その他当行借入ローン月中積数]
    ,MAX(CASE WHEN B.[商品コード]='A109900000000' THEN B.[月中平残] ELSE 0 END) AS [その他当行借入ローン月中平残]
    ,MAX(CASE WHEN B.[商品コード]='A109900000000' THEN B.[期中積数] ELSE 0 END) AS [その他当行借入ローン期中積数]
    ,MAX(CASE WHEN B.[商品コード]='A109900000000' THEN B.[期中平残] ELSE 0 END) AS [その他当行借入ローン期中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0032' THEN B.[残高]     ELSE 0 END) AS [その他ローン残高]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0032' THEN B.[月中積数] ELSE 0 END) AS [その他ローン月中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0032' THEN B.[月中平残] ELSE 0 END) AS [その他ローン月中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0032' THEN B.[期中積数] ELSE 0 END) AS [その他ローン期中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0032' THEN B.[期中平残] ELSE 0 END) AS [その他ローン期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4130000000000' THEN B.[残高]     ELSE 0 END) AS [事業者カードローン残高]
    ,MAX(CASE WHEN B.[商品コード]='4130000000000' THEN B.[月中積数] ELSE 0 END) AS [事業者カードローン月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4130000000000' THEN B.[月中平残] ELSE 0 END) AS [事業者カードローン月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4130000000000' THEN B.[期中積数] ELSE 0 END) AS [事業者カードローン期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4130000000000' THEN B.[期中平残] ELSE 0 END) AS [事業者カードローン期中平残]
    ,MAX(CASE WHEN B.[商品コード]='A080000000000' THEN B.[残高]     ELSE 0 END) AS [支払承諾残高]
    ,MAX(CASE WHEN B.[商品コード]='A080000000000' THEN B.[月中積数] ELSE 0 END) AS [支払承諾月中積数]
    ,MAX(CASE WHEN B.[商品コード]='A080000000000' THEN B.[月中平残] ELSE 0 END) AS [支払承諾月中平残]
    ,MAX(CASE WHEN B.[商品コード]='A080000000000' THEN B.[期中積数] ELSE 0 END) AS [支払承諾期中積数]
    ,MAX(CASE WHEN B.[商品コード]='A080000000000' THEN B.[期中平残] ELSE 0 END) AS [支払承諾期中平残]
    ,MAX(CASE WHEN B.[商品コード]='A110000000000' THEN B.[残高]     ELSE 0 END) AS [代理貸保証残高]
    ,MAX(CASE WHEN B.[商品コード]='A110000000000' THEN B.[月中積数] ELSE 0 END) AS [代理貸保証月中積数]
    ,MAX(CASE WHEN B.[商品コード]='A110000000000' THEN B.[月中平残] ELSE 0 END) AS [代理貸保証月中平残]
    ,MAX(CASE WHEN B.[商品コード]='A110000000000' THEN B.[期中積数] ELSE 0 END) AS [代理貸保証期中積数]
    ,MAX(CASE WHEN B.[商品コード]='A110000000000' THEN B.[期中平残] ELSE 0 END) AS [代理貸保証期中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0043' THEN B.[残高]     ELSE 0 END) AS [代理貸保証金額残高]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0043' THEN B.[月中積数] ELSE 0 END) AS [代理貸保証金額月中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0043' THEN B.[月中平残] ELSE 0 END) AS [代理貸保証金額月中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0043' THEN B.[期中積数] ELSE 0 END) AS [代理貸保証金額期中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0043' THEN B.[期中平残] ELSE 0 END) AS [代理貸保証金額期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4200000000000' THEN B.[残高]     ELSE 0 END) AS [外国為替残高]
    ,MAX(CASE WHEN B.[商品コード]='4200000000000' THEN B.[月中積数] ELSE 0 END) AS [外国為替月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4200000000000' THEN B.[月中平残] ELSE 0 END) AS [外国為替月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4200000000000' THEN B.[期中積数] ELSE 0 END) AS [外国為替期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4200000000000' THEN B.[期中平残] ELSE 0 END) AS [外国為替期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4210000000000' THEN B.[残高]     ELSE 0 END) AS [私募債残高]
    ,MAX(CASE WHEN B.[商品コード]='4210000000000' THEN B.[月中積数] ELSE 0 END) AS [私募債月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4210000000000' THEN B.[月中平残] ELSE 0 END) AS [私募債月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4210000000000' THEN B.[期中積数] ELSE 0 END) AS [私募債期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4210000000000' THEN B.[期中平残] ELSE 0 END) AS [私募債期中平残]
    ,MAX(CASE WHEN B.[商品コード]='4160000000000' THEN B.[残高]     ELSE 0 END) AS [外貨支承残高]
    ,MAX(CASE WHEN B.[商品コード]='4160000000000' THEN B.[月中積数] ELSE 0 END) AS [外貨支承月中積数]
    ,MAX(CASE WHEN B.[商品コード]='4160000000000' THEN B.[月中平残] ELSE 0 END) AS [外貨支承月中平残]
    ,MAX(CASE WHEN B.[商品コード]='4160000000000' THEN B.[期中積数] ELSE 0 END) AS [外貨支承期中積数]
    ,MAX(CASE WHEN B.[商品コード]='4160000000000' THEN B.[期中平残] ELSE 0 END) AS [外貨支承期中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0050' THEN B.[残高]     ELSE 0 END) AS [総与信合計残高]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0050' THEN B.[月中積数] ELSE 0 END) AS [総与信合計月中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0050' THEN B.[月中平残] ELSE 0 END) AS [総与信合計月中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0050' THEN B.[期中積数] ELSE 0 END) AS [総与信合計期中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0050' THEN B.[期中平残] ELSE 0 END) AS [総与信合計期中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0060' THEN B.[残高]     ELSE 0 END) AS [円貨貸出合計残高]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0060' THEN B.[月中積数] ELSE 0 END) AS [円貨貸出合計月中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0060' THEN B.[月中平残] ELSE 0 END) AS [円貨貸出合計月中平残]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0060' THEN B.[期中積数] ELSE 0 END) AS [円貨貸出合計期中積数]
    ,MAX(CASE WHEN B.[商品コード]='AZZZZZZZZ0060' THEN B.[期中平残] ELSE 0 END) AS [円貨貸出合計期中平残]
FROM
(SELECT [作成基準日],[TBN],[CFB] FROM ${INFO_DB}.[T_KT10100D_OBJ]
 WHERE [作成基準日]=(SELECT [基準日] FROM ${INFO_DB}.[T_KT90085D_OBJ])) AS A
LEFT JOIN
(SELECT [店番],[ＣＩＦ番号],[科目],[商品コード]
       ,[残高],[月中積数],[月中平残],[期中積数],[期中平残],[当初貸出日]
 FROM ${INFO_DB}.[T_KT12070D_OBJ]) AS B
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
