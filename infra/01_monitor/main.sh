#!/usr/bin/env bash
set -euo pipefail

# このスクリプトは以下を実行します:
# 1) infra/common.parameter.json を読み込む
# 2) location を検証する
# 3) Bicep デプロイを実行する

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
common_file="$repo_root/infra/common.parameter.json"

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
name="main-01_monitor-$(date +'%Y%m%dT%H%M%S')"

# 生成したパラメータでデプロイを実行する
az deployment sub create \
  --name "$name" \
  --location "$location" \
  --template-file "$repo_root/infra/01_monitor/bicep/main.bicep" \
  ${what_if:+$what_if}
