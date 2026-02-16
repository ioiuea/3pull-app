#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
infra_root="$repo_root/infra"
common_file="$infra_root/common.parameter.json"
params_dir="$infra_root/params"

log_config_file="$infra_root/config/log-analytics.json"
log_script="$infra_root/scripts/generate-log-analytics-params.py"
log_meta_file="$params_dir/log-analytics-meta.json"

appi_config_file="$infra_root/config/application-insights.json"
appi_script="$infra_root/scripts/generate-application-insights-params.py"
appi_meta_file="$params_dir/application-insights-meta.json"

vnet_config_file="$infra_root/config/virtual-network.json"
vnet_script="$infra_root/scripts/generate-virtual-network-params.py"
vnet_meta_file="$params_dir/virtual-network-meta.json"

subnets_config_file="$infra_root/config/subnets.json"
subnets_script="$infra_root/scripts/generate-subnets-params.py"
subnets_meta_file="$params_dir/subnets-meta.json"

firewall_config_file="$infra_root/config/firewall.json"
firewall_script="$infra_root/scripts/generate-firewall-params.py"
firewall_meta_file="$params_dir/firewall-meta.json"

application_gateway_config_file="$infra_root/config/application-gateway.json"
application_gateway_script="$infra_root/scripts/generate-application-gateway-params.py"
application_gateway_meta_file="$params_dir/application-gateway-meta.json"

route_tables_config_file="$infra_root/config/route-tables.json"
route_tables_script="$infra_root/scripts/generate-route-tables-params.py"
route_tables_meta_file="$params_dir/route-tables-meta.json"

nsgs_config_file="$infra_root/config/nsgs.json"
nsgs_script="$infra_root/scripts/generate-nsgs-params.py"
nsgs_meta_file="$params_dir/nsgs-meta.json"
subnet_attachments_script="$infra_root/scripts/generate-subnet-attachments-params.py"
subnet_attachments_meta_file="$params_dir/subnet-attachments-meta.json"

maintenance_vm_config_file="$infra_root/config/maintenance-vm.json"
maintenance_vm_script="$infra_root/scripts/generate-maintenance-vm-params.py"
maintenance_vm_meta_file="$params_dir/maintenance-vm-meta.json"

what_if=""
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

if [[ ! -f "$common_file" ]]; then
  echo "common parameter file が見つかりません: $common_file" >&2
  exit 1
fi

if [[ ! -f "$log_config_file" ]]; then
  echo "log analytics config file が見つかりません: $log_config_file" >&2
  exit 1
fi

if [[ ! -f "$appi_config_file" ]]; then
  echo "application insights config file が見つかりません: $appi_config_file" >&2
  exit 1
fi

if [[ ! -f "$vnet_config_file" ]]; then
  echo "virtual network config file が見つかりません: $vnet_config_file" >&2
  exit 1
fi

if [[ ! -f "$subnets_config_file" ]]; then
  echo "subnets config file が見つかりません: $subnets_config_file" >&2
  exit 1
fi

if [[ ! -f "$firewall_config_file" ]]; then
  echo "firewall config file が見つかりません: $firewall_config_file" >&2
  exit 1
fi

if [[ ! -f "$application_gateway_config_file" ]]; then
  echo "application gateway config file が見つかりません: $application_gateway_config_file" >&2
  exit 1
fi

if [[ ! -f "$route_tables_config_file" ]]; then
  echo "route tables config file が見つかりません: $route_tables_config_file" >&2
  exit 1
fi

if [[ ! -f "$nsgs_config_file" ]]; then
  echo "nsgs config file が見つかりません: $nsgs_config_file" >&2
  exit 1
fi

if [[ ! -f "$maintenance_vm_config_file" ]]; then
  echo "maintenance vm config file が見つかりません: $maintenance_vm_config_file" >&2
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI (az) が見つかりません。" >&2
  exit 1
fi

timestamp="$(date +'%Y%m%dT%H%M%S')"
mkdir -p "$params_dir"

COMMON_FILE="$common_file" \
RESOURCE_CONFIG_FILE="$log_config_file" \
PARAMS_DIR="$params_dir" \
OUT_META_FILE="$log_meta_file" \
TIMESTAMP="$timestamp" \
"$log_script"

COMMON_FILE="$common_file" \
RESOURCE_CONFIG_FILE="$appi_config_file" \
PARAMS_DIR="$params_dir" \
OUT_META_FILE="$appi_meta_file" \
TIMESTAMP="$timestamp" \
"$appi_script"

COMMON_FILE="$common_file" \
RESOURCE_CONFIG_FILE="$vnet_config_file" \
PARAMS_DIR="$params_dir" \
OUT_META_FILE="$vnet_meta_file" \
TIMESTAMP="$timestamp" \
"$vnet_script"

COMMON_FILE="$common_file" \
RESOURCE_CONFIG_FILE="$subnets_config_file" \
PARAMS_DIR="$params_dir" \
OUT_META_FILE="$subnets_meta_file" \
TIMESTAMP="$timestamp" \
"$subnets_script"

COMMON_FILE="$common_file" \
RESOURCE_CONFIG_FILE="$firewall_config_file" \
SUBNETS_CONFIG_FILE="$subnets_config_file" \
PARAMS_DIR="$params_dir" \
OUT_META_FILE="$firewall_meta_file" \
TIMESTAMP="$timestamp" \
"$firewall_script"

COMMON_FILE="$common_file" \
RESOURCE_CONFIG_FILE="$application_gateway_config_file" \
SUBNETS_CONFIG_FILE="$subnets_config_file" \
PARAMS_DIR="$params_dir" \
OUT_META_FILE="$application_gateway_meta_file" \
TIMESTAMP="$timestamp" \
"$application_gateway_script"

COMMON_FILE="$common_file" \
RESOURCE_CONFIG_FILE="$route_tables_config_file" \
SUBNETS_CONFIG_FILE="$subnets_config_file" \
FIREWALL_META_FILE="$firewall_meta_file" \
PARAMS_DIR="$params_dir" \
OUT_META_FILE="$route_tables_meta_file" \
TIMESTAMP="$timestamp" \
"$route_tables_script"

COMMON_FILE="$common_file" \
RESOURCE_CONFIG_FILE="$nsgs_config_file" \
SUBNETS_CONFIG_FILE="$subnets_config_file" \
PARAMS_DIR="$params_dir" \
OUT_META_FILE="$nsgs_meta_file" \
TIMESTAMP="$timestamp" \
"$nsgs_script"

COMMON_FILE="$common_file" \
SUBNETS_CONFIG_FILE="$subnets_config_file" \
ROUTE_TABLES_CONFIG_FILE="$route_tables_config_file" \
NSGS_CONFIG_FILE="$nsgs_config_file" \
PARAMS_DIR="$params_dir" \
OUT_META_FILE="$subnet_attachments_meta_file" \
TIMESTAMP="$timestamp" \
"$subnet_attachments_script"

COMMON_FILE="$common_file" \
RESOURCE_CONFIG_FILE="$maintenance_vm_config_file" \
SUBNETS_CONFIG_FILE="$subnets_config_file" \
PARAMS_DIR="$params_dir" \
OUT_META_FILE="$maintenance_vm_meta_file" \
TIMESTAMP="$timestamp" \
"$maintenance_vm_script"

location="$(META_FILE="$log_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("location", ""))
PY
)"

resource_group_name="$(META_FILE="$log_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("resourceGroupName", ""))
PY
)"

vnet_resource_group_name="$(META_FILE="$vnet_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("resourceGroupName", ""))
PY
)"

subnets_resource_group_name="$(META_FILE="$subnets_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("resourceGroupName", ""))
PY
)"

firewall_resource_group_name="$(META_FILE="$firewall_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("resourceGroupName", ""))
PY
)"

application_gateway_resource_group_name="$(META_FILE="$application_gateway_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("resourceGroupName", ""))
PY
)"

route_tables_resource_group_name="$(META_FILE="$route_tables_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("resourceGroupName", ""))
PY
)"

nsgs_resource_group_name="$(META_FILE="$nsgs_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("resourceGroupName", ""))
PY
)"

subnet_attachments_resource_group_name="$(META_FILE="$subnet_attachments_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("resourceGroupName", ""))
PY
)"

maintenance_vm_resource_group_name="$(META_FILE="$maintenance_vm_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("resourceGroupName", ""))
PY
)"

if [[ -z "$location" ]]; then
  echo "location が取得できませんでした。infra/common.parameter.json を確認してください。" >&2
  exit 1
fi

if [[ -z "$resource_group_name" ]]; then
  echo "resourceGroupName が取得できませんでした。config を確認してください。" >&2
  exit 1
fi

if [[ -z "$vnet_resource_group_name" ]]; then
  echo "vnet resourceGroupName が取得できませんでした。config を確認してください。" >&2
  exit 1
fi

if [[ -z "$subnets_resource_group_name" ]]; then
  echo "subnets resourceGroupName が取得できませんでした。config を確認してください。" >&2
  exit 1
fi

if [[ -z "$firewall_resource_group_name" ]]; then
  echo "firewall resourceGroupName が取得できませんでした。config を確認してください。" >&2
  exit 1
fi

if [[ -z "$application_gateway_resource_group_name" ]]; then
  echo "application gateway resourceGroupName が取得できませんでした。config を確認してください。" >&2
  exit 1
fi

if [[ -z "$route_tables_resource_group_name" ]]; then
  echo "route tables resourceGroupName が取得できませんでした。config を確認してください。" >&2
  exit 1
fi

if [[ -z "$nsgs_resource_group_name" ]]; then
  echo "nsgs resourceGroupName が取得できませんでした。config を確認してください。" >&2
  exit 1
fi

if [[ -z "$subnet_attachments_resource_group_name" ]]; then
  echo "subnet attachments resourceGroupName が取得できませんでした。config を確認してください。" >&2
  exit 1
fi

if [[ -z "$maintenance_vm_resource_group_name" ]]; then
  echo "maintenance vm resourceGroupName が取得できませんでした。config を確認してください。" >&2
  exit 1
fi

available_locations="$(az account list-locations --query "[].name" -o tsv)"
if ! printf '%s\n' "$available_locations" | grep -qx "$location"; then
  echo "location が Azure のリージョン名ではありません: $location" >&2
  exit 1
fi

echo "==> Ensure Resource Group: $resource_group_name"
az group create \
  --name "$resource_group_name" \
  --location "$location" >/dev/null

echo "==> Ensure Resource Group: $vnet_resource_group_name"
az group create \
  --name "$vnet_resource_group_name" \
  --location "$location" >/dev/null

if [[ "$subnets_resource_group_name" != "$vnet_resource_group_name" ]]; then
  echo "==> Ensure Resource Group: $subnets_resource_group_name"
  az group create \
    --name "$subnets_resource_group_name" \
    --location "$location" >/dev/null
fi

if [[ "$firewall_resource_group_name" != "$vnet_resource_group_name" && "$firewall_resource_group_name" != "$subnets_resource_group_name" ]]; then
  echo "==> Ensure Resource Group: $firewall_resource_group_name"
  az group create \
    --name "$firewall_resource_group_name" \
    --location "$location" >/dev/null
fi

if [[ "$application_gateway_resource_group_name" != "$vnet_resource_group_name" && "$application_gateway_resource_group_name" != "$subnets_resource_group_name" && "$application_gateway_resource_group_name" != "$firewall_resource_group_name" ]]; then
  echo "==> Ensure Resource Group: $application_gateway_resource_group_name"
  az group create \
    --name "$application_gateway_resource_group_name" \
    --location "$location" >/dev/null
fi

if [[ "$route_tables_resource_group_name" != "$vnet_resource_group_name" && "$route_tables_resource_group_name" != "$subnets_resource_group_name" && "$route_tables_resource_group_name" != "$firewall_resource_group_name" ]]; then
  echo "==> Ensure Resource Group: $route_tables_resource_group_name"
  az group create \
    --name "$route_tables_resource_group_name" \
    --location "$location" >/dev/null
fi

if [[ "$nsgs_resource_group_name" != "$vnet_resource_group_name" && "$nsgs_resource_group_name" != "$subnets_resource_group_name" && "$nsgs_resource_group_name" != "$firewall_resource_group_name" && "$nsgs_resource_group_name" != "$route_tables_resource_group_name" ]]; then
  echo "==> Ensure Resource Group: $nsgs_resource_group_name"
  az group create \
    --name "$nsgs_resource_group_name" \
    --location "$location" >/dev/null
fi

if [[ "$subnet_attachments_resource_group_name" != "$vnet_resource_group_name" && "$subnet_attachments_resource_group_name" != "$subnets_resource_group_name" && "$subnet_attachments_resource_group_name" != "$firewall_resource_group_name" && "$subnet_attachments_resource_group_name" != "$route_tables_resource_group_name" && "$subnet_attachments_resource_group_name" != "$nsgs_resource_group_name" ]]; then
  echo "==> Ensure Resource Group: $subnet_attachments_resource_group_name"
  az group create \
    --name "$subnet_attachments_resource_group_name" \
    --location "$location" >/dev/null
fi

if [[ "$maintenance_vm_resource_group_name" != "$vnet_resource_group_name" && "$maintenance_vm_resource_group_name" != "$subnets_resource_group_name" && "$maintenance_vm_resource_group_name" != "$firewall_resource_group_name" && "$maintenance_vm_resource_group_name" != "$route_tables_resource_group_name" && "$maintenance_vm_resource_group_name" != "$nsgs_resource_group_name" && "$maintenance_vm_resource_group_name" != "$subnet_attachments_resource_group_name" ]]; then
  echo "==> Ensure Resource Group: $maintenance_vm_resource_group_name"
  az group create \
    --name "$maintenance_vm_resource_group_name" \
    --location "$location" >/dev/null
fi

log_deploy="$(META_FILE="$log_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(str(bool(meta.get("deploy", True))).lower())
PY
)"

log_params_file="$(META_FILE="$log_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("paramsFile", ""))
PY
)"

appi_deploy="$(META_FILE="$appi_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(str(bool(meta.get("deploy", True))).lower())
PY
)"

appi_params_file="$(META_FILE="$appi_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("paramsFile", ""))
PY
)"

if [[ "$log_deploy" == "true" ]]; then
  echo "==> Deploy Log Analytics"
  az deployment group create \
    --name "main-monitor-log-analytics-${timestamp}" \
    --resource-group "$resource_group_name" \
    --parameters "$log_params_file" \
    ${what_if:+$what_if}
else
  echo "==> Skip Log Analytics (resourceToggles.logAnalytics=false)"
fi

if [[ "$appi_deploy" == "true" ]]; then
  echo "==> Deploy Application Insights"
  az deployment group create \
    --name "main-monitor-application-insights-${timestamp}" \
    --resource-group "$resource_group_name" \
    --parameters "$appi_params_file" \
    ${what_if:+$what_if}
else
  echo "==> Skip Application Insights (resourceToggles.applicationInsights=false)"
fi

vnet_deploy="$(META_FILE="$vnet_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(str(bool(meta.get("deploy", True))).lower())
PY
)"

vnet_params_file="$(META_FILE="$vnet_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("paramsFile", ""))
PY
)"

if [[ "$vnet_deploy" == "true" ]]; then
  echo "==> Deploy Virtual Network"
  az deployment group create \
    --name "main-network-virtual-network-${timestamp}" \
    --resource-group "$vnet_resource_group_name" \
    --parameters "$vnet_params_file" \
    ${what_if:+$what_if}
else
  echo "==> Skip Virtual Network (resourceToggles.virtualNetwork=false)"
fi

subnets_deploy="$(META_FILE="$subnets_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(str(bool(meta.get("deploy", True))).lower())
PY
)"

subnets_params_file="$(META_FILE="$subnets_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("paramsFile", ""))
PY
)"

if [[ "$subnets_deploy" == "true" ]]; then
  echo "==> Deploy Subnets (without NSG/RouteTable)"
  az deployment group create \
    --name "main-network-subnets-${timestamp}" \
    --resource-group "$subnets_resource_group_name" \
    --parameters "$subnets_params_file" \
    ${what_if:+$what_if}
else
  echo "==> Skip Subnets (resourceToggles.subnets=false)"
fi

firewall_deploy="$(META_FILE="$firewall_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(str(bool(meta.get("deploy", True))).lower())
PY
)"

firewall_params_file="$(META_FILE="$firewall_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("paramsFile", ""))
PY
)"

if [[ "$firewall_deploy" == "true" ]]; then
  echo "==> Deploy Firewall"
  az deployment group create \
    --name "main-network-firewall-${timestamp}" \
    --resource-group "$firewall_resource_group_name" \
    --parameters "$firewall_params_file" \
    ${what_if:+$what_if}
else
  echo "==> Skip Firewall (resourceToggles.firewall=false)"
fi

application_gateway_deploy="$(META_FILE="$application_gateway_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(str(bool(meta.get("deploy", True))).lower())
PY
)"

application_gateway_params_file="$(META_FILE="$application_gateway_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("paramsFile", ""))
PY
)"

route_tables_deploy="$(META_FILE="$route_tables_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(str(bool(meta.get("deploy", True))).lower())
PY
)"

route_tables_params_file="$(META_FILE="$route_tables_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("paramsFile", ""))
PY
)"

if [[ "$route_tables_deploy" == "true" ]]; then
  echo "==> Deploy Route Tables (UDR)"
  az deployment group create \
    --name "main-network-route-tables-${timestamp}" \
    --resource-group "$route_tables_resource_group_name" \
    --parameters "$route_tables_params_file" \
    ${what_if:+$what_if}
else
  echo "==> Skip Route Tables (resourceToggles.subnets=false)"
fi

nsgs_deploy="$(META_FILE="$nsgs_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(str(bool(meta.get("deploy", True))).lower())
PY
)"

nsgs_params_file="$(META_FILE="$nsgs_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("paramsFile", ""))
PY
)"

if [[ "$nsgs_deploy" == "true" ]]; then
  echo "==> Deploy NSGs"
  az deployment group create \
    --name "main-network-nsgs-${timestamp}" \
    --resource-group "$nsgs_resource_group_name" \
    --parameters "$nsgs_params_file" \
    ${what_if:+$what_if}
else
  echo "==> Skip NSGs (resourceToggles.subnets=false)"
fi

subnet_attachments_deploy="$(META_FILE="$subnet_attachments_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(str(bool(meta.get("deploy", True))).lower())
PY
)"

subnet_attachments_params_file="$(META_FILE="$subnet_attachments_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("paramsFile", ""))
PY
)"

if [[ "$subnet_attachments_deploy" == "true" ]]; then
  echo "==> Attach Route Tables / NSGs to Subnets"
  az deployment group create \
    --name "main-network-subnet-attachments-${timestamp}" \
    --resource-group "$subnet_attachments_resource_group_name" \
    --parameters "$subnet_attachments_params_file" \
    ${what_if:+$what_if}
else
  echo "==> Skip Subnet Attachments (resourceToggles.subnets=false)"
fi

if [[ "$application_gateway_deploy" == "true" ]]; then
  echo "==> Deploy Application Gateway"
  az deployment group create \
    --name "main-network-application-gateway-${timestamp}" \
    --resource-group "$application_gateway_resource_group_name" \
    --parameters "$application_gateway_params_file" \
    ${what_if:+$what_if}
else
  echo "==> Skip Application Gateway (resourceToggles.applicationGateway=false)"
fi

maintenance_vm_deploy="$(META_FILE="$maintenance_vm_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(str(bool(meta.get("deploy", True))).lower())
PY
)"

maintenance_vm_params_file="$(META_FILE="$maintenance_vm_meta_file" python - <<'PY'
import json
import os
from pathlib import Path

meta = json.loads(Path(os.environ["META_FILE"]).read_text(encoding="utf-8"))
print(meta.get("paramsFile", ""))
PY
)"

if [[ "$maintenance_vm_deploy" == "true" ]]; then
  if [[ -z "${MAINT_VM_ADMIN_PASSWORD:-}" ]]; then
    echo "MAINT_VM_ADMIN_PASSWORD が未設定です。" >&2
    echo "例: MAINT_VM_ADMIN_PASSWORD='YourStrongPassword!' ./main.sh --what-if" >&2
    exit 1
  fi

  echo "==> Deploy Maintenance VM"
  az deployment group create \
    --name "main-service-maintenance-vm-${timestamp}" \
    --resource-group "$maintenance_vm_resource_group_name" \
    --parameters "$maintenance_vm_params_file" \
    --parameters maintVmAdminPassword="$MAINT_VM_ADMIN_PASSWORD" \
    ${what_if:+$what_if}
else
  echo "==> Skip Maintenance VM (resourceToggles.maintenanceVm=false)"
fi
