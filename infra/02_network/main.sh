#!/usr/bin/env bash
set -euo pipefail

# このスクリプトは以下を実行します:
# 1) infra/common.parameter.json を読み込む
# 2) vnetAddressPrefixes と prefixLength からサブネットのアドレスを算出する
# 3) 一時 ARM パラメータファイルを生成する
# 4) そのパラメータで Bicep デプロイを実行する

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
common_file="$repo_root/infra/common.parameter.json"
subnet_script="$repo_root/infra/02_network/scripts/generate-subnets.py"
nsg_script="$repo_root/infra/02_network/scripts/generate-nsgs.py"
route_table_script="$repo_root/infra/02_network/scripts/generate-route-tables.py"
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
subnet_params_file="$(mktemp "$repo_root/infra/02_network/tmp-subnet-params-${timestamp}.json")"
nsg_params_file="$(mktemp "$repo_root/infra/02_network/tmp-nsg-params-${timestamp}.json")"
route_table_params_file="$(mktemp "$repo_root/infra/02_network/tmp-rt-params-${timestamp}.json")"

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

# デプロイ名は時刻付きで生成する
name="main-02_network-$(date +'%Y%m%dT%H%M%S')"

# サブネットのパラメータを生成する
COMMON_FILE="$common_file" PARAMS_FILE="$subnet_params_file" "$subnet_script"

# NSG のパラメータを生成する（サブネット一時ファイルを参照）
COMMON_FILE="$common_file" PARAMS_FILE="$nsg_params_file" SUBNET_PARAMS_FILE="$subnet_params_file" "$nsg_script"

# # Route Table のパラメータを生成する
COMMON_FILE="$common_file" PARAMS_FILE="$route_table_params_file" "$route_table_script"

# 生成したパラメータでデプロイを実行する
az deployment sub create \
  --name "$name" \
  --location "$location" \
  --template-file "$repo_root/infra/02_network/bicep/main.bicep" \
  --parameters "@$subnet_params_file" \
  --parameters "@$nsg_params_file" \
  --parameters "@$route_table_params_file" \
  ${what_if:+$what_if}

# 一時ファイルを削除する
# rm -f "$params_file"
