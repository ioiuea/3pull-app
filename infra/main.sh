#!/usr/bin/env bash
set -euo pipefail

# infra 配下の main.sh を順番に実行します（01_monitor → 02_network）。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

infra_root="$repo_root/infra"
monitor_runner="$infra_root/01_monitor/main.sh"
network_runner="$infra_root/02_network/main.sh"

if [[ ! -x "$monitor_runner" ]]; then
  echo "実行ファイルが見つかりません: $monitor_runner" >&2
  exit 1
fi

if [[ ! -x "$network_runner" ]]; then
  echo "実行ファイルが見つかりません: $network_runner" >&2
  exit 1
fi

echo "==> 01_monitor を実行します"
"$monitor_runner" ${what_if:+$what_if}

echo "==> 02_network を実行します"
"$network_runner" ${what_if:+$what_if}
