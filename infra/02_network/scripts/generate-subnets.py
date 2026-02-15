#!/usr/bin/env python3
"""
vnetAddressPrefixes と prefixLength からサブネットのアドレスを算出し、
Bicep 用の一時パラメータファイルを作成します。

このスクリプトは main.sh から呼び出す想定で、
common.parameter.json は変更しません。
"""

import json
import ipaddress
import os
from pathlib import Path

common_path = Path(os.environ["COMMON_FILE"])
params_path = Path(os.environ["PARAMS_FILE"])
subnets_config_path = Path(__file__).parent / "config" / "subnets.json"

# 共通パラメータを読み込み（VNET の範囲とサブネットサイズの元データ）
data = json.loads(common_path.read_text())
base_prefixes = [ipaddress.ip_network(p) for p in data.get("vnetAddressPrefixes", [])]
subnets = json.loads(subnets_config_path.read_text())
shared_bastion_ip = str(data.get("sharedBastionIp", "")).strip()

if shared_bastion_ip:
    subnets = [subnet for subnet in subnets if subnet.get("alias") != "bastion"]

if not base_prefixes:
    raise SystemExit("vnetAddressPrefixes is empty")

# VNET プレフィクスの先頭から順にサブネットを割り当てる。
# prefixLength の小さい順（＝大きいブロック）を先に割り当てる。
range_index = 0
current = int(base_prefixes[0].network_address)
resolved = []

for subnet in sorted(subnets, key=lambda s: s["prefixLength"]):
    prefix_len = subnet["prefixLength"]
    allocated = None

    while range_index < len(base_prefixes):
        rng = base_prefixes[range_index]
        block = 1 << (32 - prefix_len)

        # サブネットのブロック境界に合わせる
        if current % block != 0:
            current = ((current // block) + 1) * block

        net = ipaddress.ip_network((current, prefix_len))

        # 現在の VNET 範囲に収まる場合は採用して次へ進める
        if net.subnet_of(rng):
            allocated = net
            current = int(net.broadcast_address) + 1
            break

        # 収まらない場合は次の VNET 範囲へ移動する
        range_index += 1
        if range_index < len(base_prefixes):
            current = int(base_prefixes[range_index].network_address)

    if allocated is None:
        raise SystemExit(f"subnet '{subnet['name']}' does not fit in vnetAddressPrefixes")

    resolved_entry = {
        **subnet,
        "alias": subnet.get("alias", subnet.get("name")),
        "addressPrefix": str(allocated),
    }
    resolved.append(resolved_entry)
# 算出済みサブネットを Bicep に渡すための ARM パラメータを生成する
params = {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "subnets": {
            "value": resolved
        }
    },
}

params_path.write_text(json.dumps(params, indent=2) + "\n")
