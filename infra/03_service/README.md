## 初期構築時の実行方法

初期構築時は `infra/README.md` の手順に従い、`infra/main.sh` を実行してください。  
`infra/main.sh` から `03_service` の `main.sh` が呼び出され、リソースが作成されます。

## 個別実行（更新用）

このフォルダの `main.sh` を直接実行することで、`03_service` を単体で更新できます。  
**前提要件:** `01_monitor` と `02_network` を先に実行済みで、そこで作成されるリソースが存在していること。

## フォルダ構成

- `bicep/`
  - `main.maint_vm.bicep`: maint VM 作成のエントリポイント
  - `modules/virtualMachine.bicep`: NIC + VM モジュール
- `scripts/`
  - `generate-maint-vm-params.py`: `infra/common.parameter.json` と `02_network` 由来のサブネット計算結果から maint VM 用パラメータを生成
  - `main.maint_vm.sh`: Bicep デプロイ実行
- `main.sh`
  - location 検証、パラメータ生成、デプロイ実行を統括

# Azureログイン

Azure CLIを利用してAzureへログインします。

```bash
az login
```

# 操作対象のサブスクリプションIDを設定

操作対象のサブスクリプションを設定します。

```bash
az account set --subscription {SubscriptionId}
```

現在選択中のサブスクリプション確認します。

```bash
az account show
```

### デプロイ

プロジェクトルートから infra/03_service フォルダへ移動します。

```bash
cd infra/03_service
```

#### デプロイの流れ

- `03_service`（phase 1）
  - `MaintenanceSubnet` 内に **メンテナンス用 VM (Linux)** を作成
  - `infra/common.parameter.json` を元に `02_network/scripts/generate-subnets.py` でサブネットを動的計算
  - 計算済み `MaintenanceSubnet` から VM のサブネット名を生成して利用

#### 必須環境変数

- `MAINT_VM_ADMIN_PASSWORD`
  - メンテナンス用 VM の管理者パスワード（Bicep の secure parameter に渡します）

実行例:

```bash
MAINT_VM_ADMIN_PASSWORD='YourStrongPassword!' ./main.sh --what-if
```

#### デプロイコマンド（dry-run）

サブスクリプションスコープでデプロイコマンド（dry-run）を実行し出力を確認します。

```bash
MAINT_VM_ADMIN_PASSWORD='YourStrongPassword!' ./main.sh --what-if
```

#### デプロイコマンド

```bash
MAINT_VM_ADMIN_PASSWORD='YourStrongPassword!' ./main.sh
```

## IaC対象外の手順（メンテVM作成後）

以下は現時点では IaC には含めず、手動で実施します。

### EntraIDログイン有効化

- 以下コマンドで AAD ログイン拡張機能を有効化します。

```bash
az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory \
    --name AADSSHLoginForLinux \
    --resource-group rg-[environmentName]-[systemName]-svc \
    --vm-name vm-[environmentName]-[systemName]-maint
```

- ログイン対象アカウントに、対象VMへ以下いずれかの RBAC ロールを付与してください。
  - 仮想マシン管理者ログイン
  - 仮想マシンユーザーログイン

### ログイン手順

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
