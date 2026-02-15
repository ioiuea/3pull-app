#!/usr/bin/env python3
"""
02_network で算出したサブネット情報から、maint VM 用の ARM パラメータを生成する。

入力:
- COMMON_FILE: infra/common.parameter.json
- SUBNET_PARAMS_FILE: generate-subnets.py が出力したパラメータファイル
- PARAMS_FILE: 出力先パラメータファイル
"""

import json
import os
from pathlib import Path

common_path = Path(os.environ["COMMON_FILE"])
subnet_params_path = Path(os.environ["SUBNET_PARAMS_FILE"])
params_path = Path(os.environ["PARAMS_FILE"])

common = json.loads(common_path.read_text())
subnet_params = json.loads(subnet_params_path.read_text())

environment_name = common.get("environmentName", "")
system_name = common.get("systemName", "")

if not environment_name or not system_name:
    raise SystemExit("environmentName または systemName が common.parameter.json に設定されていません")

subnets = subnet_params.get("parameters", {}).get("subnets", {}).get("value", [])
if not subnets:
    raise SystemExit("subnets パラメータが空です")

maint_subnet = next(
    (
        subnet
        for subnet in subnets
        if subnet.get("alias") == "maint" or subnet.get("name") == "MaintenanceSubnet"
    ),
    None,
)

if maint_subnet is None:
    raise SystemExit("maint サブネットが見つかりませんでした")

maint_subnet_name = maint_subnet["name"]

params = {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "maintVmName": {
            "value": f"vm-{environment_name}-{system_name}-maint"
        },
        "maintNicName": {
            "value": f"nic-vm-{environment_name}-{system_name}-maint"
        },
        "maintSubnetName": {
            "value": maint_subnet_name
        },
    },
}

params_path.write_text(json.dumps(params, indent=2) + "\n")
