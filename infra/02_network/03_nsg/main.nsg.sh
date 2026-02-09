#!/usr/bin/env bash
set -euo pipefail

# 03_nsg: NSG 作成のみを担当します。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
common_file="${COMMON_FILE:-$repo_root/infra/common.parameter.json}"
nsg_params_file="${NSG_PARAMS_FILE:-}"
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

if [[ -z "$nsg_params_file" ]]; then
  echo "NSG_PARAMS_FILE が未設定です。" >&2
  exit 1
fi

if [[ -z "$location" ]]; then
  echo "LOCATION が未設定です。" >&2
  exit 1
fi

name="main-02_network-nsg-$(date +'%Y%m%dT%H%M%S')"

az deployment sub create \
  --name "$name" \
  --location "$location" \
  --template-file "$repo_root/infra/02_network/03_nsg/bicep/main.bicep" \
  --parameters "@$nsg_params_file" \
  ${what_if:+$what_if}
