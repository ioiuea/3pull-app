#!/usr/bin/env python3
"""
common.parameter.json の設定から Route Table 定義を生成し、
params ファイルへ出力します。
"""

import json
import os
from pathlib import Path

common_path = Path(os.environ["COMMON_FILE"])
params_path = Path(os.environ["PARAMS_FILE"])
subnets_config_path = Path(__file__).parents[2] / "01_subnets" / "scripts" / "config" / "subnets.json"
egress_config_path = Path(__file__).parent / "config" / "egress.json"

# 共通パラメータを読み込み
data = json.loads(common_path.read_text())
subnets = json.loads(subnets_config_path.read_text())

# サブネット名（エイリアス）の集合
subnet_aliases = {s.get("alias", s.get("name", "")) for s in subnets}

# アウトバウンド（ユーザー定義ルート）の設定
next_hop_ip = data.get("egressNextHopIp", "")
egress_targets = json.loads(egress_config_path.read_text()).get("subnetNames", [])

route_tables = []
subnet_route_table_map = {}

if next_hop_ip:
    # Route Table 本体
    route_tables.append(
        {
            "name": "egress",
            "routes": [
                {
                    "name": "udr-internet-egress-route",
                    "properties": {
                        "addressPrefix": "0.0.0.0/0",
                        "nextHopType": "VirtualAppliance",
                        "nextHopIpAddress": next_hop_ip,
                    },
                }
            ],
            "subnetNames": [],
        }
    )

    # 対象サブネットへ紐付け
    for subnet_alias in egress_targets:
        if subnet_alias in subnet_aliases:
            route_tables[0]["subnetNames"].append(subnet_alias)
            subnet_route_table_map[subnet_alias] = "egress"

# Route Table 定義のみを持つ params を生成する
params = {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "routeTables": {"value": route_tables},
        "subnetRouteTableMap": {"value": subnet_route_table_map},
    },
}

params_path.write_text(json.dumps(params, indent=2) + "\n")
