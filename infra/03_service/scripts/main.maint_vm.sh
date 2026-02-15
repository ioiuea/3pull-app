#!/usr/bin/env bash
set -euo pipefail

# maint VM のデプロイのみを担当する。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
maint_vm_params_file="${MAINT_VM_PARAMS_FILE:-}"
location="${LOCATION:-}"
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

if [[ -z "$maint_vm_params_file" ]]; then
  echo "MAINT_VM_PARAMS_FILE が未設定です。" >&2
  exit 1
fi

if [[ -z "$location" ]]; then
  echo "LOCATION が未設定です。" >&2
  exit 1
fi

if [[ -z "${MAINT_VM_ADMIN_PASSWORD:-}" ]]; then
  echo "MAINT_VM_ADMIN_PASSWORD が未設定です。" >&2
  exit 1
fi

name="main-03_service-maint-vm-$(date +'%Y%m%dT%H%M%S')"

az deployment sub create \
  --name "$name" \
  --location "$location" \
  --template-file "$repo_root/infra/03_service/bicep/main.maint_vm.bicep" \
  --parameters "@$maint_vm_params_file" \
  --parameters maintVmAdminPassword="$MAINT_VM_ADMIN_PASSWORD" \
  ${what_if:+$what_if}
