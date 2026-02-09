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

## VNET のサイズ要件

最低限、以下のいずれかのアドレスレンジが必要です。

- `/24` が 3 つ分  
- `/23` と `/24` の組み合わせ

## サブネット構成（固定）

サブネットは固定で、用途は以下のとおりです。

| サブネット名 | 用途 |
| --- | --- |
| `AzureFirewallSubnet` | Azure Firewall を配置 |
| `SystemNodeSubnet` | AKS ノード用サブネット |
| `WorkloadSubnet` | AKS ワークロード用サブネット |
| `ClusterServicesSubnet` | AKS クラスタ内サービス用サブネット |
| `ApplicationGatewaySubnet` | Application Gateway (AppGW) を配置 |
| `PrivateEndpointSubnet` | DB や LLM（OpenAI など）を含む各種 PaaS の Private Endpoint 用 |
| `MaintenanceSubnet` | デプロイや保守用の VM を配置 |

## egress（アウトバウンド）ルート

ハブ&スポーク構成などで **集約された FW 経由のアウトバウンド**が必要な場合、  
`egressNextHopIp` に IP を指定すると **ユーザー定義ルート (UDR)** が作成されます。  
これにより AKS からの外向き通信経路を制御できます。  
指定しない場合は **UDR を作成しません**。

## Ingress の通信経路

Ingress は以下の経路とします。

```
AppGW → FW → AKS
```

### この経路にする理由

FW を前面に置くと **NAT で送信元が変わり**、  
AppGW + WAF が **クライアント情報を正しく識別できなくなる**ためです。  
そのため、AppGW + WAF を前面に配置し、FW を経由して AKS に到達する構成にしています。

## 実行順のまとめ

infra 配下では `main.sh` を実行すると、以下の順で処理されます。

```
01_monitor → 02_network
```
