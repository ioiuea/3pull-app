#!/usr/bin/env bash
set -euo pipefail

# 02_firewall: Firewall 作成のみを担当します。
# 成功時は Firewall のプライベート IP を stdout に出力します。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
common_file="${COMMON_FILE:-$repo_root/infra/common.parameter.json}"
subnet_params_file="${SUBNET_PARAMS_FILE:-}"
firewall_params_file="${FIREWALL_PARAMS_FILE:-}"
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

if [[ -z "$location" ]]; then
  echo "LOCATION が未設定です。" >&2
  exit 1
fi

if [[ -z "$subnet_params_file" ]]; then
  echo "SUBNET_PARAMS_FILE が未設定です。" >&2
  exit 1
fi

if [[ -z "$firewall_params_file" ]]; then
  echo "FIREWALL_PARAMS_FILE が未設定です。" >&2
  exit 1
fi

name="main-02_network-firewall-$(date +'%Y%m%dT%H%M%S')"

if [[ -n "$what_if" ]]; then
  az deployment sub create \
    --name "$name" \
    --location "$location" \
    --template-file "$repo_root/infra/02_network/bicep/main.firewall.bicep" \
    ${what_if:+$what_if}
  exit 0
fi

actual_ip="$(az deployment sub create \
  --name "$name" \
  --location "$location" \
  --template-file "$repo_root/infra/02_network/bicep/main.firewall.bicep" \
  --query "properties.outputs.firewallPrivateIp.value" \
  -o tsv)"

if [[ -z "$actual_ip" ]]; then
  echo "Firewall のプライベート IP が取得できませんでした。" >&2
  exit 1
fi

FIREWALL_PRIVATE_IP="$actual_ip" python - <<'PY'
import json
import os
from pathlib import Path

params_path = Path(os.environ["FIREWALL_PARAMS_FILE"])
ip = os.environ["FIREWALL_PRIVATE_IP"]
data = json.loads(params_path.read_text())
data.setdefault("parameters", {}).setdefault("firewallPrivateIp", {})["value"] = ip
params_path.write_text(json.dumps(data, indent=2) + "\n")
PY
