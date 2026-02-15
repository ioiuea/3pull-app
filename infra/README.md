# infra/ README

このディレクトリの Bicep で構築されるインフラ構成の概要をまとめます。

## 前提要件

- Azure CLI (`az`) が利用できること
- Python が利用できること

## 実行前の準備（共通パラメータ）

デプロイ前に `infra/common.parameter.json` を **必ず自分の環境に合わせて編集**してください。

### location

Azure で許可されるリージョン名を指定します。  
リージョン一覧は次のコマンドで確認できます。

```bash
az account list-locations --query "[].name" -o tsv
```

### environmentName

`prod` / `stg` / `dev` などの **任意の環境名**を指定します。  
リソース名やタグに埋め込まれます。

### systemName

システム名を指定します。  
リソース名やタグに埋め込まれます。

### enableFirewallIdps

IDS/IPS を有効にするかどうかを指定します。  
`true` の場合は **Firewall SKU が Premium** になり、IDS/IPS を有効化します。  
`false` の場合は **Firewall SKU が Standard** になります。

### ddosProtectionPlanId

Azure DDoS Protection Plan のリソース ID を指定します。  
指定した場合のみ VNET で DDoS Protection が有効になります。  
未指定（空文字）の場合は DDoS Protection Plan を自動作成して適用します。
入力例: `/subscriptions/<subscriptionId>/resourceGroups/<resourceGroupName>/providers/Microsoft.Network/ddosProtectionPlans/<ddosPlanName>`

### vnetAddressPrefixes

VNET のアドレス空間を指定します。  
最低限、以下のいずれかのアドレスレンジが必要です。

- `/24` が 3 つ分
- `/23` と `/24` の組み合わせ

### egressNextHopIp

アウトバンド通信でFWを経由した通信を行います。
ハブ&スポーク構成などで **集約された FW 経由のアウトバウンド**が必要な場合、  
この IP を指定すると **ユーザー定義ルート (UDR)** が作成されます。
指定しない場合は **VNET 内に構築される Firewall の IP が自動で設定**されます。

補足として、インバウンド通信は **構築した Firewall を経由してワークロードへ到達**する経路になります。

### sharedBastionIp

踏み台サーバなど、メンテ用サブネット（保守用 VM）へアクセス可能な **許可 IP** を指定します。  
指定しない場合はメンテ用サブネット向けの NSG を作成しないため、VM への通信は **すべて許可**されます。

## ネットワーク構成の詳細

サブネット構成やルート/NSG の設計方針は [docs/network.md](../docs/network.md) を参照してください。

## デプロイ手順

### Azureログイン

Azure CLI を利用して Azure へログインします。

```bash
az login
```

### 操作対象のサブスクリプションIDを設定

操作対象のサブスクリプションを設定します。

```bash
az account set --subscription {SubscriptionId}
```

現在選択中のサブスクリプション確認します。

```bash
az account show
```

### デプロイ

プロジェクトルートから infra フォルダへ移動します。

```bash
cd infra
```

#### デプロイの流れ

- `01_monitor`
  - **Azure Log Analytics Workspace** と **Azure Application Insights** を作成
- `02_network`
  - **Azure Virtual Network (VNet)** / **Subnets** / **User Defined Route (UDR)** / **Network Security Group (NSG)** を作成してサブネットと紐づけ
- `03_service`（phase 1）
  - **MaintenanceSubnet** 内に **メンテナンス用 VM (Linux)** を作成

`infra/common.parameter.json` を読み込み、実行時にサブネットの `addressPrefix` などを動的に計算しパラメータとして生成しデプロイを行います。

`03_service` の実行には `MAINT_VM_ADMIN_PASSWORD` 環境変数が必要です。  

#### デプロイコマンド（dry-run）

サブスクリプションスコープでデプロイコマンド（dry-run）を実行し出力を確認します。

```bash
MAINT_VM_ADMIN_PASSWORD='YourStrongPassword!' ./main.sh --what-if
```

#### デプロイコマンド

```bash
MAINT_VM_ADMIN_PASSWORD='YourStrongPassword!' ./main.sh
```

## IaC対象外の手順（03_service 実行後）

`03_service` でメンテVM作成後、以下は手動手順です。

### EntraIDログイン有効化

```bash
az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory \
    --name AADSSHLoginForLinux \
    --resource-group rg-[environmentName]-[systemName]-svc \
    --vm-name vm-[environmentName]-[systemName]-maint
```

対象アカウントに、対象VMへ以下いずれかの RBAC ロール付与が必要です。

- 仮想マシン管理者ログイン
- 仮想マシンユーザーログイン

### VMログイン

```bash
az login
az ssh vm -n vm-[environmentName]-[systemName]-maint -g rg-[environmentName]-[systemName]-svc
```

### メンテVM内での azure-cli インストール

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
