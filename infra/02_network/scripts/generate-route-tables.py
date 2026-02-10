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
subnet_params_path = Path(os.environ["SUBNET_PARAMS_FILE"])
firewall_params_path = Path(os.environ["FIREWALL_PARAMS_FILE"])
subnets_config_path = Path(__file__).parent / "config" / "subnets.json"
outbound_config_path = Path(__file__).parent / "config" / "outbound.json"

# 共通パラメータを読み込み
data = json.loads(common_path.read_text())
subnets = json.loads(subnets_config_path.read_text())
subnet_params = json.loads(subnet_params_path.read_text())
firewall_params = json.loads(firewall_params_path.read_text())

# サブネット名（エイリアス）の集合
subnet_aliases = {s.get("alias", s.get("name", "")) for s in subnets}

# サブネット名/エイリアスからアドレスプレフィクスを引けるようにする
resolved_subnets = subnet_params.get("parameters", {}).get("subnets", {}).get("value", [])
subnet_prefix_map = {}
for subnet in resolved_subnets:
    subnet_name = subnet.get("name", "")
    subnet_alias = subnet.get("alias", subnet_name)
    prefix = subnet.get("addressPrefix", "")
    if subnet_name:
        subnet_prefix_map[subnet_name] = prefix
    if subnet_alias:
        subnet_prefix_map[subnet_alias] = prefix

firewall_ip = (
    firewall_params.get("parameters", {})
    .get("firewallPrivateIp", {})
    .get("value", "")
)

# 01) agic -> firewall のルート
route_tables = []

agic_alias = "agic"
firewall_alias = "firewall"
agic_prefix = subnet_prefix_map.get(agic_alias, "")
if not firewall_ip or not agic_prefix:
    raise SystemExit("firewallPrivateIp or ApplicationGatewaySubnet prefix is missing")

route_tables.append(
    {
        "name": firewall_alias,
        "routes": [
            {
                "name": "udr-firewall-inbound",
                "properties": {
                    "addressPrefix": agic_prefix,
                    "nextHopType": "VirtualAppliance",
                    "nextHopIpAddress": firewall_ip,
                },
            }
        ],
        "subnetNames": [agic_alias],
    }
)

# 02) outbound（ユーザー定義ルート）の設定
next_hop_ip = data.get("egressNextHopIp", "") or firewall_ip
outbound_targets = json.loads(outbound_config_path.read_text()).get("subnetNames", [])

if next_hop_ip:
    # IP 形式チェック
    import ipaddress

    try:
        ipaddress.ip_address(next_hop_ip)
    except ValueError as exc:
        raise SystemExit("egressNextHopIp is not a valid IP address") from exc

    # Route Table 本体
    route_tables.append(
        {
            "name": "outbound",
            "routes": [
                {
                    "name": "udr-internet-outbound",
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
    for subnet_alias in outbound_targets:
        if subnet_alias in subnet_aliases:
            route_tables[-1]["subnetNames"].append(subnet_alias)

# Route Table 定義のみを持つ params を生成する
params = {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "routeTables": {"value": route_tables},
    },
}

params_path.write_text(json.dumps(params, indent=2) + "\n")
