#!/usr/bin/env python3
"""
サブネット一時ファイルを基に、ルートテーブルと NSG の紐づけ情報を
反映したサブネット定義を生成します。
"""

import json
import os
from pathlib import Path

common_path = Path(os.environ["COMMON_FILE"])
params_path = Path(os.environ["PARAMS_FILE"])
subnet_params_path = Path(os.environ["SUBNET_PARAMS_FILE"])
route_params_path = Path(os.environ["ROUTE_TABLE_PARAMS_FILE"])
nsg_params_path = Path(os.environ["NSG_PARAMS_FILE"])

common_data = json.loads(common_path.read_text())
subnet_params = json.loads(subnet_params_path.read_text())
route_params = json.loads(route_params_path.read_text())
nsg_params = json.loads(nsg_params_path.read_text())

environment = common_data.get("environmentName", "")
system = common_data.get("systemName", "")

subnets = subnet_params.get("parameters", {}).get("subnets", {}).get("value", [])
route_tables = route_params.get("parameters", {}).get("routeTables", {}).get("value", [])
nsgs = nsg_params.get("parameters", {}).get("nsgs", {}).get("value", [])

nsg_name_by_alias = {nsg.get("subnetName", ""): f"nsg-{environment}-{system}-{nsg.get('subnetName', '')}" for nsg in nsgs}
route_name_by_alias = {}
for route_table in route_tables:
    name = route_table.get("name", "")
    for subnet_alias in route_table.get("subnetNames", []):
        route_name_by_alias[subnet_alias] = name

policy_subnets = []
for subnet in subnets:
    alias = subnet.get("alias", "")
    route_suffix = route_name_by_alias.get(alias, "")
    policy_subnets.append(
        {
            "name": subnet.get("name", ""),
            "alias": alias,
            "addressPrefix": subnet.get("addressPrefix", ""),
            "networkSecurityGroupName": nsg_name_by_alias.get(alias, ""),
            "routeTableName": f"rt-{environment}-{system}-{route_suffix}" if route_suffix else "",
        }
    )

params = {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "subnets": {"value": policy_subnets},
    },
}

params_path.write_text(json.dumps(params, indent=2) + "\n")
