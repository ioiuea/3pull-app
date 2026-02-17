# infra README

このディレクトリは、Azure インフラを Bicep でデプロイする実行基盤です。  
`main.sh` が `common.parameter.json` を読み込み、前処理で `.bicepparam` を動的生成して各リソースをデプロイします。

## このフォルダ配下の説明

- `main.sh`
  - エントリーポイント。パラメータ生成とデプロイを順序制御します。
- `common.parameter.json`
  - 共通パラメータと、どのリソースをデプロイ対象にするか（実行可否）を管理します。
- `bicep/`
  - リソース単位の Bicep 本体。
- `scripts/`
  - `main.sh` から呼び出される前処理スクリプト（`.bicepparam` 生成）。
- `config/`
  - 原則、ユーザーが変更しない固定定義。
- `params/`
  - 動的生成される `.bicepparam` / `*-meta.json` の出力先。

## 前提要件

- Azure CLI (`az`) が利用できること
- Python 3 が利用できること

## 実行前の準備（共通パラメータ）

デプロイ前に `infra/common.parameter.json` を環境に合わせて設定してください。

### location

Azure の有効なリージョン名を指定します。  
リージョン一覧確認:

```bash
az account list-locations --query "[].name" -o tsv
```

### environmentName

`prod` / `stg` / `dev` などの環境名です。任意の文字列を指定できます。リソース名とタグに反映されます。

### systemName

システム名です。リソース名とタグに反映されます。

### enableFirewallIdps

IDS/IPS を有効にするかどうかを指定します。  
`true` の場合は **Firewall SKU が Premium** になり、IDS/IPS を有効化します。  
`false` の場合は **Firewall SKU が Standard** になります。

### enableDdosProtection

DDoS Protection の有効/無効を指定します。  
`true` の場合は、DDoS Protection Plan を（既存利用または新規作成して）VNET に適用します。  
`false` の場合は、DDoS Protection Plan の作成をスキップし、VNET への DDoS Protection 適用もしません。

### ddosProtectionPlanId

`enableDdosProtection=true` の場合に利用される設定です。  
未指定の場合は、`ddos-[environmentName]-[systemName]` の DDoS Protection Plan を新規作成して VNET に適用します。  
企業ポリシー等により既存の保護プランを利用する場合は、そのリソース ID を指定してください。  
入力例: `/subscriptions/<subscriptionId>/resourceGroups/<resourceGroupName>/providers/Microsoft.Network/ddosProtectionPlans/<ddosPlanName>`

### vnetAddressPrefixes

VNET のアドレス空間です。サブネットを動的計算するため、以下の最低限レンジが必要です。

- `/24` が 3 つ分
- 連続するレンジを確保できる場合は、`/23` が 1 つ分 + `/24` が 1 つ分、または `/22` が 1 つ分（`/24` 3 つ分相当）

### egressNextHopIp

AKS ノード系サブネットやメンテナンス VM サブネットからのアウトバウンド経路を制御するための設定です。  
基本（未指定）の場合は、新規作成した Firewall のプライベート IP を next hop とするユーザー定義ルート（UDR）を作成します。  
企業ポリシー上、ハブ＆スポーク構成で VNET ピアリングされた集約アウトバウンド経路を使う必要がある場合は、この値に IP を指定することで UDR の宛先（next hop）をその IP に書き換えます。

### sharedBastionIp

メンテナンス VM 用サブネット（`MaintenanceSubnet`）に対して通信を許可する送信元を指定します。  
基本（未指定）の場合は、新規作成される `AzureBastionSubnet` からの通信のみ許可します。  
企業ポリシー上、ハブ＆スポーク構成で VNET ピアリングされた集約踏み台サーバを利用する必要がある場合は、この値に IP を指定することで NSG の許可送信元を書き換えます。  
許可される通信は SSH（22）と RDP（3389）です。

注記:

- `AzureBastionSubnet` は作成しますが、Azure Bastion サービス本体は自動作成しません。
- 企業ポリシーによって Azure Bastion が利用不可のケースもあるため、Bastion または踏み台サーバは要件に合わせて手動で作成してください。

### aksUserPoolVmSize

Azure Kubernetes Service「ユーザープール」（アプリ用ノード）の VM サイズです。  
アプリの同時実行数、CPU/メモリ要件、コストに直接影響します。

- 例: `Standard_D4s_v4`（中規模）
- 目安:
  - 小規模検証: `Standard_D2s_v4`
  - 本番寄り: `Standard_D4s_v4` 以上

### aksUserPoolCount / aksUserPoolMinCount / aksUserPoolMaxCount

Azure Kubernetes Service「ユーザープール」（アプリ用ノード）の ノード台数です。
オートスケーリング時の下限/上限もここで指定します。

- `aksUserPoolCount`: 初期ノード数
- `aksUserPoolMinCount`: 自動縮退時の最小ノード数
- `aksUserPoolMaxCount`: 自動拡張時の最大ノード数

必須条件:

- `aksUserPoolMinCount <= aksUserPoolCount <= aksUserPoolMaxCount`

### aksUserPoolLabel

Azure Kubernetes Service「ユーザープール」（アプリ用ノード）の ノードラベル値です。  
Azure Kubernetes Service では `pool=<この値>` のラベルがノードに付き、Pod の `nodeSelector` / `affinity` で配置先制御に使います。

- 例: `user`, `batch`, `api`

### aksPodCidr

Azure Kubernetes Service の Pod に割り当てる IP 範囲（CIDR）です。  
Overlay CNI では VNET サブネットとは別空間で管理されます。  
ただし、AKS マニフェストやネットワーク設計によって外部との通信経路が成立する構成では、重複 IP が競合する可能性があります。  
そのため、下記のような接続がある場合は、競合しないレンジから採番することを推奨します。  

- この AKS から VNET ピアリング先の別 VNET（別 AKS クラスタを含む）へ通信する場合
- この AKS から VPN/ExpressRoute 経由でオンプレミス環境へ通信する場合
- 逆に、別 VNET やオンプレミス側からこの AKS（Pod 宛）へ到達させる場合

- 例: `10.189.0.0/17`
- 形式: `x.x.x.x/xx`

### aksServiceCidr

Kubernetes Service（ClusterIP）用の IP 範囲（CIDR）です。  
`dnsServiceIP` はこのレンジ内の 10 番目の利用可能 IP を自動設定します。

- 例: `10.47.0.0/24`
- 形式: `x.x.x.x/xx`
- 注意:
  - `vnetAddressPrefixes` と重複不可
  - `aksPodCidr` と重複不可
  - 利用可能 IP が 10 個以上必要

### resourceToggles

リソース単位の実行可否です。

- `logAnalytics`
- `applicationInsights`
- `virtualNetwork`
- `subnets`
  - `subnets`, `route-tables`, `nsgs`, `subnet-attachments` を一括制御
- `firewall`
- `applicationGateway`
- `aks`
- `maintenanceVm`

## ネットワーク構成ドキュメント

サブネット構成やルート/NSG の設計方針は [docs/network.md](../docs/network.md) を参照してください。

## デプロイ手順

### Azureログイン

```bash
az login
```

### 操作対象サブスクリプションの設定

```bash
az account set --subscription {SubscriptionId}
az account show
```

### デプロイ

```bash
cd infra
MAINT_VM_ADMIN_PASSWORD='YourStrongPassword!' ./main.sh --what-if
MAINT_VM_ADMIN_PASSWORD='YourStrongPassword!' ./main.sh
```

### デプロイの流れ

- monitor
  - Log Analytics Workspace
  - Application Insights
- network
  - Virtual Network
  - Subnets（作成のみ）
  - Firewall
  - Route Tables
  - NSGs
  - Subnet Attachments（RouteTable/NSG紐づけ）
  - Application Gateway
- service
  - AKS
  - Maintenance VM

## 出力ファイル（params/）

- `log-analytics.bicepparam`
- `application-insights.bicepparam`
- `virtual-network.bicepparam`
- `subnets.bicepparam`
- `firewall.bicepparam`
- `route-tables.bicepparam`
- `nsgs.bicepparam`
- `subnet-attachments.bicepparam`
- `application-gateway.bicepparam`
- `aks.bicepparam`
- `maintenance-vm.bicepparam`

補足:

- `params/` 配下は生成物として `.gitignore` 対象です（`.gitkeep` を除く）。

## メンテVM作成後の個別手順

### 目的

メンテVMへの安全な運用アクセスを有効化し、運用作業に必要な CLI を利用可能にします。

### 1. Entra ID ログイン拡張の有効化

```bash
az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory \
    --name AADSSHLoginForLinux \
    --resource-group rg-[environmentName]-[systemName]-maint \
    --vm-name vm-[environmentName]-[systemName]-maint
```

対象アカウントに以下いずれかの RBAC ロール付与が必要です。

- 仮想マシン管理者ログイン
- 仮想マシンユーザーログイン

### 2. メンテVMへログイン

```bash
az login
az ssh vm -n vm-[environmentName]-[systemName]-maint -g rg-[environmentName]-[systemName]-maint
```

### 3. メンテVM内で Azure CLI を利用する場合

```shell
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg

AZ_DIST=$(lsb_release -cs)
echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${AZ_DIST}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-by: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/azure-cli.sources

sudo apt-get update
sudo apt-get install azure-cli
```

- メンテVM仕様の詳細: [docs/maint-vm.md](../docs/maint-vm.md)
