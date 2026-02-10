#!/usr/bin/env bash
set -euo pipefail

# このスクリプトは以下を実行します:
# 1) infra/common.parameter.json を読み込む
# 2) vnetAddressPrefixes と prefixLength からサブネットのアドレスを算出する
# 3) 一時 ARM パラメータファイルを生成する
# 4) 01_subnets → 02_firewall → 03_network_policy を順に実行する

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
common_file="$repo_root/infra/common.parameter.json"
subnet_script="$repo_root/infra/02_network/01_subnets/scripts/generate-subnets.py"
subnets_runner="$repo_root/infra/02_network/01_subnets/main.subnets.sh"
firewall_script="$repo_root/infra/02_network/02_firewall/scripts/generate-firewall-params.py"
firewall_runner="$repo_root/infra/02_network/02_firewall/main.firewall.sh"
route_script="$repo_root/infra/02_network/03_network_policy/scripts/generate-route-tables.py"
nsg_script="$repo_root/infra/02_network/03_network_policy/scripts/generate-nsgs.py"
subnet_policy_script="$repo_root/infra/02_network/03_network_policy/scripts/generate-subnet-policy-params.py"
network_policy_runner="$repo_root/infra/02_network/03_network_policy/main.network_policy.sh"
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

timestamp="$(date +'%Y%m%dT%H%M%S')"
params_dir="$repo_root/infra/log"
subnet_params_file="$(mktemp "$params_dir/tmp-subnet-params-${timestamp}.json")"
firewall_params_file="$(mktemp "$params_dir/tmp-firewall-params-${timestamp}.json")"
route_params_file="$(mktemp "$params_dir/tmp-route-params-${timestamp}.json")"
nsg_params_file="$(mktemp "$params_dir/tmp-nsg-params-${timestamp}.json")"
subnet_policy_params_file="$(mktemp "$params_dir/tmp-subnet-policy-params-${timestamp}.json")"

# location を common.parameter.json から取得する（検証は後で行う）
location=$(COMMON_FILE="$common_file" python - <<'PY'
import json
from pathlib import Path
import os

data = json.loads(Path(os.environ["COMMON_FILE"]).read_text())
print(data.get("location", ""))
PY
)

# location が空の場合はエラーにして common.parameter.json の設定を促す
if [[ -z "$location" ]]; then
  echo "location が取得できませんでした。infra/common.parameter.json に必ず設定してください。" >&2
  exit 1
fi

# location は Azure のリージョン名のみ許可する
if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI (az) が見つかりません。location の検証ができないため終了します。" >&2
  exit 1
fi

available_locations="$(az account list-locations --query "[].name" -o tsv)"
if ! printf '%s\n' "$available_locations" | grep -qx "$location"; then
  echo "location が Azure のリージョン名ではありません: $location" >&2
  echo "infra/common.parameter.json に正しいリージョン名を設定してください。" >&2
  echo "指定可能なロケーション一覧:" >&2
  printf '%s\n' "$available_locations" >&2
  exit 1
fi

# --------------------
# 01_subnets
# --------------------

# パラメータ生成
COMMON_FILE="$common_file" PARAMS_FILE="$subnet_params_file" "$subnet_script"

# サブネット作成
COMMON_FILE="$common_file" LOCATION="$location" SUBNET_PARAMS_FILE="$subnet_params_file" "$subnets_runner" ${what_if:+$what_if}

# --------------------
# 02_firewall
# --------------------

# パラメータ生成
firewall_private_ip="$(SUBNET_PARAMS_FILE="$subnet_params_file" PARAMS_FILE="$firewall_params_file" "$firewall_script")"

# ファイアウォール作成
COMMON_FILE="$common_file" LOCATION="$location" SUBNET_PARAMS_FILE="$subnet_params_file" FIREWALL_PARAMS_FILE="$firewall_params_file" "$firewall_runner" ${what_if:+$what_if}

# --------------------
# 03_network_policy
# --------------------

# パラメータ生成（ユーザー定義ルート）
COMMON_FILE="$common_file" PARAMS_FILE="$route_params_file" SUBNET_PARAMS_FILE="$subnet_params_file" FIREWALL_PARAMS_FILE="$firewall_params_file" "$route_script"

# パラメータ生成（ネットワークセキュリティグループ）
COMMON_FILE="$common_file" PARAMS_FILE="$nsg_params_file" SUBNET_PARAMS_FILE="$subnet_params_file" "$nsg_script"

# パラメータ生成（サブネット更新用）
COMMON_FILE="$common_file" PARAMS_FILE="$subnet_policy_params_file" SUBNET_PARAMS_FILE="$subnet_params_file" ROUTE_TABLE_PARAMS_FILE="$route_params_file" NSG_PARAMS_FILE="$nsg_params_file" "$subnet_policy_script"

# ルートテーブル作成 + NSG 作成 + サブネット紐づけ
COMMON_FILE="$common_file" LOCATION="$location" SUBNET_POLICY_PARAMS_FILE="$subnet_policy_params_file" ROUTE_TABLE_PARAMS_FILE="$route_params_file" NSG_PARAMS_FILE="$nsg_params_file" "$network_policy_runner" ${what_if:+$what_if}

# if [[ -z "$firewall_private_ip" ]]; then
#   echo "Firewall 用の固定 IP が取得できませんでした。" >&2
#   exit 1
# fi

# if [[ -n "$what_if" ]]; then
#   COMMON_FILE="$common_file" LOCATION="$location" SUBNET_PARAMS_FILE="$subnet_params_file" FIREWALL_PARAMS_FILE="$firewall_params_file" "$firewall_runner" ${what_if:+$what_if} >/dev/null
# else
#   COMMON_FILE="$common_file" LOCATION="$location" SUBNET_PARAMS_FILE="$subnet_params_file" FIREWALL_PARAMS_FILE="$firewall_params_file" "$firewall_runner" >"$firewall_ip_file"
#   actual_firewall_ip="$(cat "$firewall_ip_file" | tr -d '\n')"
#   if [[ -n "$actual_firewall_ip" && "$actual_firewall_ip" != "$firewall_private_ip" ]]; then
#     echo "Warning: Firewall の実IPが固定IPと一致しませんでした。fixed=$firewall_private_ip actual=$actual_firewall_ip" >&2
#   fi
# fi
