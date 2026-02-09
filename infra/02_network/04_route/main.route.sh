#!/usr/bin/env bash
set -euo pipefail

# 04_route: Route Table 作成とサブネット紐づけを担当します。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
common_file="${COMMON_FILE:-$repo_root/infra/common.parameter.json}"
subnet_params_file="${SUBNET_PARAMS_FILE:-}"
route_table_params_file="${ROUTE_TABLE_PARAMS_FILE:-}"
firewall_private_ip="${FIREWALL_PRIVATE_IP:-}"
location="${LOCATION:-}"
what_if=""

# 許容する引数は --what-if のみ
while [[ $# -gt 0 ]]; do
  case "$1" in
    --what-if)
      what_if="--what-if"
      shift
      ;;
    *)
      echo "許可されていない引数です: $1" >&2
      echo "利用可能な引数: --what-if" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$subnet_params_file" ]]; then
  echo "SUBNET_PARAMS_FILE が未設定です。" >&2
  exit 1
fi

if [[ -z "$route_table_params_file" ]]; then
  echo "ROUTE_TABLE_PARAMS_FILE が未設定です。" >&2
  exit 1
fi

if [[ -z "$firewall_private_ip" ]]; then
  echo "FIREWALL_PRIVATE_IP が未設定です。" >&2
  exit 1
fi

if [[ -z "$location" ]]; then
  echo "LOCATION が未設定です。" >&2
  exit 1
fi

name="main-02_network-route-$(date +'%Y%m%dT%H%M%S')"

az deployment sub create \
  --name "$name" \
  --location "$location" \
  --template-file "$repo_root/infra/02_network/04_route/bicep/main.bicep" \
  --parameters "@$subnet_params_file" \
  --parameters "@$route_table_params_file" \
  --parameters firewallPrivateIp="$firewall_private_ip" \
  ${what_if:+$what_if}
