#!/usr/bin/env python3
"""
サブネット一時パラメータから AzureFirewallSubnet の先頭使用可能 IP を算出し、  # 目的の説明
Firewall 用のパラメータファイルを生成します。  # 出力の説明
"""

import ipaddress  # IP アドレス操作に使用
import json  # JSON の読み書きに使用
import os  # 環境変数の取得に使用
from pathlib import Path  # パス操作に使用

params_path = Path(os.environ["SUBNET_PARAMS_FILE"])  # サブネット一時パラメータのパス
output_path = Path(os.environ["PARAMS_FILE"])  # 出力パラメータファイルのパス

data = json.loads(params_path.read_text())  # サブネット一時パラメータを読み込む
subnets = data.get("parameters", {}).get("subnets", {}).get("value", [])  # サブネット配列を取得

# AzureFirewallSubnet の情報を探す
fw = next((s for s in subnets if s.get("name") == "AzureFirewallSubnet"), None)  # Firewall 用サブネット
if not fw:  # 見つからない場合はエラー
    raise SystemExit("AzureFirewallSubnet is missing in subnet params")

# サブネットのアドレスレンジから使用可能な IP を取得する
net = ipaddress.ip_network(fw["addressPrefix"])  # CIDR をネットワーク型に変換
hosts = list(net.hosts())  # 使用可能なホスト IP 一覧
print(hosts)
if not hosts:  # 使用可能 IP がない場合はエラー
    raise SystemExit("No usable IPs in AzureFirewallSubnet")

firewall_ip = str(hosts[0])  # 先頭の使用可能 IP を固定 IP として採用

# Firewall 用パラメータファイルの内容を組み立てる
params = {  # ARM パラメータの形式に合わせる
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",  # スキーマ
    "contentVersion": "1.0.0.0",  # バージョン
    "parameters": {  # パラメータ本体
        "firewallPrivateIp": {  # Firewall の固定 IP
            "value": firewall_ip  # 算出した IP を設定
        }
    },
}

output_path.write_text(json.dumps(params, indent=2) + "\n")  # パラメータファイルを書き出す
print(firewall_ip)  # main.sh 用に IP を標準出力へ返す
