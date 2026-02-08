#!/usr/bin/env python3  # Python 3 実行用のシバン
"""  # モジュールの説明開始
common.parameter.json のサブネット定義（nsg-rule を含む）と、  # 入力の説明
config/nsg_rule_templates.json のテンプレートを使って NSG 定義を生成します。  # 処理の説明
"""  # モジュールの説明終了

import json  # JSON の読み書きに使用
import os  # 環境変数の取得に使用
from pathlib import Path  # パス操作に使用

common_path = Path(os.environ["COMMON_FILE"])  # common.parameter.json のパス
params_path = Path(os.environ["PARAMS_FILE"])  # 出力先 params ファイルのパス
subnet_params_path = Path(os.environ["SUBNET_PARAMS_FILE"])  # サブネット一時ファイルのパス
rule_template_path = Path(__file__).parent / "config" / "nsg_rule_templates.json"  # ルールテンプレート

# 共通パラメータを読み込み（サブネット nsg-rule を参照）
common_data = json.loads(common_path.read_text())  # common.parameter.json を読み込み
subnet_defs = common_data.get("subnets", [])  # サブネット定義（name / nsg-rule / prefixLength）

# サブネット名と nsg-rule の対応表を作成
nsg_rule_to_name = {s.get("nsg-rule", ""): s.get("name", "") for s in subnet_defs}  # nsg-rule → name
name_to_nsg_rule = {s.get("name", ""): s.get("nsg-rule", "") for s in subnet_defs}  # name → nsg-rule

# サブネット情報はサブネット作成スクリプトの一時ファイルから読み込む
subnet_params = json.loads(subnet_params_path.read_text())  # サブネット一時ファイルを読み込み
resolved_subnets = subnet_params.get("parameters", {}).get("subnets", {}).get("value", [])  # サブネット配列
subnet_prefix_map = {subnet["name"]: subnet["addressPrefix"] for subnet in resolved_subnets}  # サブネット名→アドレス

# ルールテンプレートを読み込む
rule_template_data = json.loads(rule_template_path.read_text())  # テンプレート JSON を読み込み
templates = rule_template_data.get("templates", [])  # templates 配列

# nsg-rule でテンプレートを引けるようにする
template_by_nsg_rule = {t.get("targetNsgRule", ""): t for t in templates}  # nsg-rule → template

nsgs = []  # 出力する NSG 定義の配列
for subnet in resolved_subnets:  # 各サブネットについて NSG を作成
    rules = []  # そのサブネットに適用するルール配列
    subnet_name = subnet.get("name", "")  # サブネット名
    subnet_nsg_rule = name_to_nsg_rule.get(subnet_name, "")  # サブネットの nsg-rule
    template = template_by_nsg_rule.get(subnet_nsg_rule)  # 対象テンプレートを取得

    if template:  # テンプレートがあればルールを構築
        for rule in template.get("rules", []):  # ルール定義を走査
            direction = rule.get("direction", "Inbound")  # 方向

            # direction に応じて source / destination を補完
            source = rule.get("source", "*")  # 送信元（@self/@nsg-rule:xxx など）
            destination = rule.get("destination", "*")  # 宛先（@self/@nsg-rule:xxx など）
            if direction == "Inbound" and "destination" not in rule:  # Inbound の宛先が未指定なら
                destination = subnet_nsg_rule or subnet_name  # 対象サブネットを宛先にする
            if direction == "Outbound" and "source" not in rule:  # Outbound の送信元が未指定なら
                source = subnet_nsg_rule or subnet_name  # 対象サブネットを送信元にする

            def resolve_token(value: str) -> str:  # 特殊トークンを実体に解決
                if value == "@self":  # 自分自身のサブネット
                    return subnet_nsg_rule or subnet_name
                if value.startswith("@nsg-rule:"):  # nsg-rule 指定
                    return value.split(":", 1)[1]
                return value  # それ以外はそのまま

            source = resolve_token(source)  # 送信元の特殊トークンを解決
            destination = resolve_token(destination)  # 宛先の特殊トークンを解決

            # nsg-rule → name に解決（解決できない場合はそのまま）
            source_name = nsg_rule_to_name.get(source, source)  # 送信元のサブネット名
            destination_name = nsg_rule_to_name.get(destination, destination)  # 宛先のサブネット名

            def format_name(value: str) -> str:  # ルール名表示用の整形
                if value == "*":  # 任意は Any に置換
                    return "Any"
                nsg_rule_value = name_to_nsg_rule.get(value, value)  # name なら nsg-rule に変換
                if isinstance(nsg_rule_value, str):  # 文字列なら
                    if nsg_rule_value.endswith("-nsg"):  # -nsg は除去
                        nsg_rule_value = nsg_rule_value[: -len("-nsg")]
                    if nsg_rule_value:  # 空でなければ先頭大文字
                        return nsg_rule_value[:1].upper() + nsg_rule_value[1:]
                return value  # それ以外はそのまま

            # ルール名は From/To 形式
            if direction == "Inbound":  # Inbound なら From 形式
                rule_name = f"{rule.get('access', 'Allow')}From{format_name(source_name)}"  # 例: AllowFromAks
            else:  # Outbound なら To 形式
                rule_name = f"{rule.get('access', 'Allow')}To{format_name(destination_name)}"  # 例: AllowToAfw

            rules.append(  # ルールを追加
                {  # ルール定義オブジェクト
                    "name": rule_name,  # ルール名
                    "properties": {  # ルールプロパティ
                        "sourceAddressPrefix": subnet_prefix_map.get(source_name, source),  # 送信元アドレス
                        "sourcePortRange": rule.get("sourcePortRange", "*"),  # 送信元ポート
                        "destinationAddressPrefix": subnet_prefix_map.get(destination_name, destination),  # 宛先アドレス
                        "destinationPortRange": rule.get("destinationPortRange", "*"),  # 宛先ポート
                        "protocol": rule.get("protocol", "*"),  # プロトコル
                        "access": rule.get("access", "Allow"),  # Allow/Deny
                        "priority": rule.get("priority", 100),  # 優先度
                        "direction": direction,  # 方向
                    },  # properties 終了
                }  # ルール定義オブジェクト終了
            )  # ルール追加終了

    nsgs.append(  # サブネット単位の NSG を追加
        {  # NSG 定義オブジェクト
            "subnetName": subnet_name,  # 対象サブネット名
            "securityRules": rules,  # ルール配列（テンプレートなしなら空）
        }  # NSG 定義オブジェクト終了
    )  # NSG 追加終了

# NSG 定義のみを持つ params を生成する
params = {  # パラメータファイルの本体
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",  # スキーマ
    "contentVersion": "1.0.0.0",  # バージョン
    "parameters": {  # パラメータ定義
        "nsgs": {  # NSG パラメータ
            "value": nsgs  # NSG の配列
        }  # nsgs 終了
    },  # parameters 終了
}  # params 終了

params_path.write_text(json.dumps(params, indent=2) + "\n")  # params を JSON として保存
