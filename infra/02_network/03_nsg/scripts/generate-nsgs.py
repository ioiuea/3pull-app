#!/usr/bin/env python3  # Python 3 実行用のシバン
"""  # モジュールの説明開始
common.parameter.json のサブネット定義と、  # 入力の説明
config/nsg_rule_templates.json のテンプレートを使って NSG 定義を生成します。  # 処理の説明
"""  # モジュールの説明終了

import json  # JSON の読み書きに使用
import os  # 環境変数の取得に使用
from pathlib import Path  # パス操作に使用

common_path = Path(os.environ["COMMON_FILE"])  # common.parameter.json のパス
params_path = Path(os.environ["PARAMS_FILE"])  # 出力先 params ファイルのパス
subnet_params_path = Path(os.environ["SUBNET_PARAMS_FILE"])  # サブネット一時ファイルのパス
rule_template_path = Path(__file__).parent / "config" / "nsg.json"  # ルールテンプレート
subnets_config_path = Path(__file__).parents[2] / "01_subnets" / "scripts" / "config" / "subnets.json"  # サブネット定義

# 共通パラメータを読み込み（サブネット定義のみ参照）
common_data = json.loads(common_path.read_text())  # common.parameter.json を読み込み
subnet_defs = json.loads(subnets_config_path.read_text())  # サブネット定義（name / alias / prefixLength）

# サブネット名とエイリアスの集合を作成
subnet_aliases = {s.get("alias", s.get("name", "")) for s in subnet_defs}  # サブネットエイリアス一覧
alias_by_name = {s.get("name", ""): s.get("alias", s.get("name", "")) for s in subnet_defs}  # name -> alias
name_by_alias = {s.get("alias", s.get("name", "")): s.get("name", "") for s in subnet_defs}  # alias -> name

# サブネット情報はサブネット作成スクリプトの一時ファイルから読み込む
subnet_params = json.loads(subnet_params_path.read_text())  # サブネット一時ファイルを読み込み
resolved_subnets = subnet_params.get("parameters", {}).get("subnets", {}).get("value", [])  # サブネット配列
subnet_prefix_map = {}  # サブネット名/エイリアス→アドレス
for subnet in resolved_subnets:  # 生成済みサブネットからマップを作成
    subnet_name = subnet.get("name", "")  # リソース名
    subnet_alias = subnet.get("alias", alias_by_name.get(subnet_name, subnet_name))  # エイリアス
    prefix = subnet.get("addressPrefix", "")  # アドレス
    if subnet_name:
        subnet_prefix_map[subnet_name] = prefix  # name でも引けるように
    if subnet_alias:
        subnet_prefix_map[subnet_alias] = prefix  # alias でも引けるように

# ルールテンプレートを読み込む
rule_template_data = json.loads(rule_template_path.read_text())  # テンプレート JSON を読み込み
templates = rule_template_data.get("templates", [])  # templates 配列

# サブネット名でテンプレートを引けるようにする
template_by_subnet = {t.get("targetSubnet", ""): t for t in templates}  # alias → template

nsgs = []  # 出力する NSG 定義の配列
for subnet in resolved_subnets:  # 各サブネットについて NSG を作成
    rules = []  # そのサブネットに適用するルール配列
    subnet_name = subnet.get("name", "")  # リソース名
    subnet_alias = subnet.get("alias", alias_by_name.get(subnet_name, subnet_name))  # エイリアス
    template = template_by_subnet.get(subnet_alias)  # 対象テンプレートを取得

    if template:  # テンプレートがあればルールを構築
        for rule in template.get("rules", []):  # ルール定義を走査
            direction = rule.get("direction", "Inbound")  # 方向

            # direction に応じて source / destination を補完
            source = rule.get("source", "*")  # 送信元（サブネット名 or 特殊値）
            destination = rule.get("destination", "*")  # 宛先（サブネット名 or 特殊値）
            if direction == "Inbound" and "destination" not in rule:  # Inbound の宛先が未指定なら
                destination = subnet_alias  # 対象サブネットを宛先にする
            if direction == "Outbound" and "source" not in rule:  # Outbound の送信元が未指定なら
                source = subnet_alias  # 対象サブネットを送信元にする

            def format_name(value: str) -> str:  # ルール名表示用の整形
                if value == "*":  # 任意は Any に置換
                    return "Any"
                if value in subnet_aliases:  # サブネット名なら先頭大文字化
                    return value[:1].upper() + value[1:]
                return value  # それ以外はそのまま

            # ルール名は From/To 形式
            if direction == "Inbound":  # Inbound なら From 形式
                rule_name = f"{rule.get('access', 'Allow')}From{format_name(source)}"  # 例: AllowFromServices
            else:  # Outbound なら To 形式
                rule_name = f"{rule.get('access', 'Allow')}To{format_name(destination)}"  # 例: AllowToFirewall

            rules.append(  # ルールを追加
                {  # ルール定義オブジェクト
                    "name": rule_name,  # ルール名
                    "properties": {  # ルールプロパティ
                        "sourceAddressPrefix": subnet_prefix_map.get(source, source),  # 送信元アドレス
                        "sourcePortRange": rule.get("sourcePortRange", "*"),  # 送信元ポート
                        "destinationAddressPrefix": subnet_prefix_map.get(destination, destination),  # 宛先アドレス
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
            "subnetName": subnet_alias,  # 対象サブネット名（エイリアス）
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
