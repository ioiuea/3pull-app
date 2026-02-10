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
未指定（空文字）の場合は DDoS Protection を有効にしません。

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

サブネット構成やルート/NSG の設計方針は `docs/network.md` を参照してください。

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

サブスクリプションスコープでデプロイコマンド（dry-run）を実行し出力を確認します。  
`infra/common.parameter.json` を読み込み、実行時にサブネットの `addressPrefix` などを動的に計算しパラメータとして生成しデプロイを行います。

#### デプロイの流れ
- `01_monitor`
  - **Azure Log Analytics Workspace** と **Azure Application Insights** を作成
- `02_network`
  - **Azure Virtual Network (VNet)** / **Subnets** / **User Defined Route (UDR)** / **Network Security Group (NSG)** を作成してサブネットと紐づけ

#### デプロイコマンド（dry-run）

```bash
./main.sh --what-if
```

#### デプロイコマンド

```bash
./main.sh
```
