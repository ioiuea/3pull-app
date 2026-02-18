#!/usr/bin/env python3
"""infra/common.parameter.json の入力値を事前検証する。

方針:
- ここで共通パラメータを先に検証し、後続の各 generate スクリプトでは
  正常系処理に集中できるようにする。
- 不正値がある場合は理由を一覧表示し、main.sh の実処理を停止する。
"""

from __future__ import annotations

import ipaddress
import json
import sys
from pathlib import Path


def parse_json(path: Path):
    """JSON ファイルを読み込み、構文エラー時は終了コード 1 で停止する。"""
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"[ERROR] common parameter file が見つかりません: {path}", file=sys.stderr)
        raise SystemExit(1)
    except json.JSONDecodeError as exc:
        print(f"[ERROR] common parameter file の JSON 形式が不正です: {path}", file=sys.stderr)
        print(f"        {exc}", file=sys.stderr)
        raise SystemExit(1)


def as_bool(value, key: str, errors: list[str]):
    """bool を期待するキーの型検証を行う。"""
    if isinstance(value, bool):
        return value
    errors.append(f"{key}: true/false で指定してください。")
    return None


def as_non_empty_str(value, key: str, errors: list[str]):
    """空文字でない文字列かどうかを検証する。"""
    if isinstance(value, str) and value.strip() != "":
        return value.strip()
    errors.append(f"{key}: 空でない文字列を指定してください。")
    return None


def as_optional_ip_or_cidr(value, key: str, errors: list[str]):
    """任意入力の IPv4/CIDR 文字列を検証する。空文字は未指定扱い。"""
    if value == "":
        return None
    if not isinstance(value, str):
        errors.append(f"{key}: IPv4 アドレス/CIDR 文字列か空文字を指定してください。")
        return None
    try:
        if "/" in value:
            ipaddress.ip_network(value, strict=True)
        else:
            ipaddress.ip_address(value)
    except ValueError:
        errors.append(f"{key}: 有効な IP アドレスまたは CIDR 形式ではありません。指定値={value!r}")
        return None
    return value


def as_optional_ip(value, key: str, errors: list[str]):
    """任意入力の IPv4 文字列を検証する。空文字は未指定扱い。"""
    if value == "":
        return None
    if not isinstance(value, str):
        errors.append(f"{key}: IPv4 アドレス文字列か空文字を指定してください。")
        return None
    try:
        ipaddress.ip_address(value)
    except ValueError:
        errors.append(f"{key}: 有効な IP アドレス形式ではありません。指定値={value!r}")
        return None
    return value


def as_cidr(value, key: str, errors: list[str]):
    """必須 CIDR 文字列を検証し、正常時は ip_network を返す。"""
    if not isinstance(value, str) or value.strip() == "":
        errors.append(f"{key}: x.x.x.x/xx 形式の CIDR を指定してください。")
        return None
    try:
        return ipaddress.ip_network(value, strict=True)
    except ValueError:
        errors.append(f"{key}: 有効な CIDR 形式ではありません。指定値={value!r}")
        return None


def as_int(value, key: str, errors: list[str]):
    """整数値を検証する（bool は int として扱わない）。"""
    if isinstance(value, bool) or not isinstance(value, int):
        errors.append(f"{key}: 整数を指定してください。")
        return None
    return value


def main() -> int:
    """エントリポイント。検証結果に応じた終了コードを返す。"""
    if len(sys.argv) != 2:
        print("Usage: validate-common-params.py <common.parameter.json>", file=sys.stderr)
        return 2

    common_path = Path(sys.argv[1])
    common = parse_json(common_path)

    errors: list[str] = []

    if not isinstance(common, dict):
        print("[ERROR] common parameter file のトップレベルは object である必要があります。", file=sys.stderr)
        return 1

    common_values = common.get("common")
    network_values = common.get("network")
    aks_values = common.get("aks")

    if not isinstance(common_values, dict):
        errors.append("common: object で指定してください。")
        common_values = {}
    if not isinstance(network_values, dict):
        errors.append("network: object で指定してください。")
        network_values = {}
    if not isinstance(aks_values, dict):
        errors.append("aks: object で指定してください。")
        aks_values = {}

    # 基本識別子
    as_non_empty_str(common_values.get("location"), "common.location", errors)
    as_non_empty_str(common_values.get("environmentName"), "common.environmentName", errors)
    as_non_empty_str(common_values.get("systemName"), "common.systemName", errors)

    # ネットワーク/セキュリティ系のフラグ
    as_bool(network_values.get("enableFirewallIdps"), "network.enableFirewallIdps", errors)
    enable_ddos = as_bool(network_values.get("enableDdosProtection"), "network.enableDdosProtection", errors)
    as_bool(
        network_values.get("enableGatewayRoutePropagation"),
        "network.enableGatewayRoutePropagation",
        errors,
    )
    as_bool(
        network_values.get("enableCentralizedPrivateDns"),
        "network.enableCentralizedPrivateDns",
        errors,
    )

    ddos_plan_id = network_values.get("ddosProtectionPlanId")
    if not isinstance(ddos_plan_id, str):
        errors.append("network.ddosProtectionPlanId: 文字列で指定してください（未指定は空文字）。")
    elif enable_ddos and ddos_plan_id and not ddos_plan_id.startswith("/subscriptions/"):
        errors.append(
            "network.ddosProtectionPlanId: 指定時は Azure リソース ID 形式（/subscriptions/...）で指定してください。"
        )

    # VNET アドレス空間の検証（形式と重複チェック）
    vnet_prefixes_raw = network_values.get("vnetAddressPrefixes")
    vnet_prefixes: list[ipaddress._BaseNetwork] = []
    if not isinstance(vnet_prefixes_raw, list) or not vnet_prefixes_raw:
        errors.append("network.vnetAddressPrefixes: 1件以上の CIDR 配列で指定してください。")
    else:
        for i, raw in enumerate(vnet_prefixes_raw):
            net = as_cidr(raw, f"network.vnetAddressPrefixes[{i}]", errors)
            if net is not None:
                vnet_prefixes.append(net)

        for i in range(len(vnet_prefixes)):
            for j in range(i + 1, len(vnet_prefixes)):
                if vnet_prefixes[i].overlaps(vnet_prefixes[j]):
                    errors.append(
                        "network.vnetAddressPrefixes: レンジが重複しています "
                        f"({vnet_prefixes[i]} と {vnet_prefixes[j]})"
                    )

    # 任意指定 IP
    as_optional_ip(network_values.get("egressNextHopIp", ""), "network.egressNextHopIp", errors)
    as_optional_ip_or_cidr(network_values.get("sharedBastionIp", ""), "network.sharedBastionIp", errors)
    vnet_dns_servers = network_values.get("vnetDnsServers")
    if not isinstance(vnet_dns_servers, list):
        errors.append("network.vnetDnsServers: IPv4 アドレス配列で指定してください（未指定は空配列）。")
    else:
        for i, raw in enumerate(vnet_dns_servers):
            as_optional_ip(raw, f"network.vnetDnsServers[{i}]", errors)

    # AKS user pool 設定
    as_non_empty_str(aks_values.get("userPoolVmSize"), "aks.userPoolVmSize", errors)
    count = as_int(aks_values.get("userPoolCount"), "aks.userPoolCount", errors)
    min_count = as_int(aks_values.get("userPoolMinCount"), "aks.userPoolMinCount", errors)
    max_count = as_int(aks_values.get("userPoolMaxCount"), "aks.userPoolMaxCount", errors)
    as_non_empty_str(aks_values.get("userPoolLabel"), "aks.userPoolLabel", errors)

    if count is not None and count < 0:
        errors.append("aks.userPoolCount: 0 以上を指定してください。")
    if min_count is not None and min_count < 0:
        errors.append("aks.userPoolMinCount: 0 以上を指定してください。")
    if max_count is not None and max_count < 0:
        errors.append("aks.userPoolMaxCount: 0 以上を指定してください。")

    if count is not None and min_count is not None and max_count is not None:
        if not (min_count <= count <= max_count):
                errors.append(
                "aks.userPoolCount / aks.userPoolMinCount / "
                "aks.userPoolMaxCount: min <= count <= max を満たしてください。"
            )

    # AKS ネットワーク設定
    pod_cidr = as_cidr(aks_values.get("podCidr"), "aks.podCidr", errors)
    service_cidr = as_cidr(aks_values.get("serviceCidr"), "aks.serviceCidr", errors)

    if service_cidr is not None:
        host_count = sum(1 for _ in service_cidr.hosts())
        if host_count < 10:
            errors.append("aks.serviceCidr: DNS service IP 算出のため、利用可能 IP が 10 個以上必要です。")

    if pod_cidr is not None and service_cidr is not None and pod_cidr.overlaps(service_cidr):
        errors.append("aks.podCidr と aks.serviceCidr は重複できません。")

    if service_cidr is not None:
        for vnet in vnet_prefixes:
            if service_cidr.overlaps(vnet):
                errors.append(
                    "aks.serviceCidr は network.vnetAddressPrefixes と重複できません: "
                    f"serviceCidr={service_cidr}, vnet={vnet}"
                )

    # リソース実行トグル
    toggles = common.get("resourceToggles")
    expected_toggle_keys = [
        "logAnalytics",
        "applicationInsights",
        "virtualNetwork",
        "subnets",
        "firewall",
        "applicationGateway",
        "keyVault",
        "aks",
        "maintenanceVm",
    ]
    if not isinstance(toggles, dict):
        errors.append("resourceToggles: object で指定してください。")
    else:
        for key in expected_toggle_keys:
            if key not in toggles:
                errors.append(f"resourceToggles.{key}: 未設定です。true/false を指定してください。")
            elif not isinstance(toggles[key], bool):
                errors.append(f"resourceToggles.{key}: true/false で指定してください。")

    if errors:
        print("[ERROR] infra/common.parameter.json に不正な値があります。修正して再実行してください。", file=sys.stderr)
        for msg in errors:
            print(f"  - {msg}", file=sys.stderr)
        return 1

    print(f"[OK] common parameters validated: {common_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
