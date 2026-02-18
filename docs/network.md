# 仮想ネットワーク

- ※[]内は`infra/common.parameter.json`の設定値に従って設定されます。

| 仮想ネットワーク名                  | リソースグループ名                   | 場所       | アドレス空間          | DNSサーバー | DDoS Protection                                 | DDoS保護プラン                                                        |
| ----------------------------------- | ------------------------------------ | ---------- | --------------------- | ----------- | ----------------------------------------------- | --------------------------------------------------------------------- |
| vnet-[common.environmentName]-[common.systemName] | rg-[common.environmentName]-[common.systemName]-nw | [common.location] | [network.vnetAddressPrefixes] | [network.vnetDnsServers] 未指定時は Azure提供、指定時は指定DNSサーバー | [network.enableDdosProtection] に応じて有効/無効        | [network.enableDdosProtection] と [network.ddosProtectionPlanId] に応じて既存利用/新規作成/未適用 |

- ※ `network.enableDdosProtection=true` の場合
  - `network.ddosProtectionPlanId` 指定あり: 指定した既存 DDoS 保護プランを適用
  - `network.ddosProtectionPlanId` 未指定: DDoS 保護プランを新規作成して適用
- ※ `network.enableDdosProtection=false` の場合
  - DDoS 保護プランは作成せず、VNET への DDoS Protection 適用もしません
- ※ `network.vnetDnsServers` 未指定（空配列）の場合は Azure 提供 DNS を利用し、指定した場合はその DNS サーバーを利用します。
- ※ ハブ&スポーク構成で集約 DNS を利用する場合、ハブ側 Firewall のプライベート IP など、到達可能な DNS サーバー IP を指定します。
- ※最低限、以下のいずれかのアドレスレンジが必要です。
  - `/24` が 3 つ分
  - 連続するサブネットレンジを確保できる場合は `/23` が 1 つ分 + `/24` が 1 つ分、もしくは `/22` が 1 つ分（`/24` 3 つ分相当）

# サブネット

| サブネット名               | プレフィクス | サービスエンドポイント | NSG名                                        | ルートテーブル名                           | 備考                                   |
| -------------------------- | ------------ | ---------------------- | -------------------------------------------- | ------------------------------------------ | -------------------------------------- |
| `UserNodeSubnet`           | `/24`        |                        | nsg-[common.environmentName]-[common.systemName]-usernode  | rt-[common.environmentName]-[common.systemName]-outbound-aks | アプリデプロイ領域                     |
| `ApplicationGatewaySubnet` | `/25`        |                        |                                              | rt-[common.environmentName]-[common.systemName]-firewall | AGIC用サブネット                       |
| `AgentNodeSubnet`          | `/26`        |                        | nsg-[common.environmentName]-[common.systemName]-agentnode | rt-[common.environmentName]-[common.systemName]-outbound-aks | AKSのエージェントノード用サブネット    |
| `PrivateEndpointSubnet`    | `/26`        |                        | nsg-[common.environmentName]-[common.systemName]-pep       |                                            | プライベートエンドポイント用サブネット |
| `AzureFirewallSubnet`      | `/26`        |                        |                                              |                                            | ファイヤーウォール用サブネット         |
| `AzureBastionSubnet`       | `/26`        |                        |                                              |                                            | Bastion用サブネット（`network.sharedBastionIp` 未指定時のみ） |
| `MaintenanceSubnet`        | `/29`        |                        | nsg-[common.environmentName]-[common.systemName]-maint     | rt-[common.environmentName]-[common.systemName]-outbound-maint | メンテVM用サブネット                   |

※ `PrivateEndpointSubnet` に NSG を適用して通信制御するため、サブネット設定の `privateEndpointNetworkPolicies` は有効化します。

※ 以下のサブネットへのネットワークセキュリティグループの設定はAzure非推奨であり予期せぬエラーが発生する可能性があるため設定しません。

- `AzureFirewallSubnet`
- `ApplicationGatewaySubnet`
- `AzureBastionSubnet`

# 構成図（生成パラメータ例）

![基本構成図](assets/basic-pattern.png)

## 通信経路フロー（UDR）

以下は、サブネットの UDR 経路を可視化した図です。

```mermaid
flowchart LR
  AG["ApplicationGatewaySubnet<br/>10.189.129.0/25"]
  U["UserNodeSubnet<br/>10.189.128.0/24"]
  N["AgentNodeSubnet<br/>10.189.130.64/26"]
  M["MaintenanceSubnet<br/>10.189.130.128/29"]
  FW["Azure Firewall<br/>10.189.129.196"]
  NET["0.0.0.0/0 (Internet)"]

  RTFW["rt-dev-3pull-firewall<br/>udr-usernode-inbound<br/>udr-agentnode-inbound"]
  RTAKS["rt-dev-3pull-outbound-aks<br/>udr-appgw-return<br/>udr-internet-outbound"]
  RTM["rt-dev-3pull-outbound-maint<br/>udr-internet-outbound"]

  AG ---|"紐づけ"| RTFW
  U ---|"紐づけ"| RTAKS
  N ---|"紐づけ"| RTAKS
  M ---|"紐づけ"| RTM

  RTFW -->|"UserNodeSubnet 宛 / AgentNodeSubnet 宛<br/>next hop: 10.189.129.196"| FW
  RTAKS -->|"ApplicationGatewaySubnet 宛<br/>next hop: 10.189.129.196"| FW
  RTAKS -->|"0.0.0.0/0<br/>next hop: 10.189.129.196 または network.egressNextHopIp"| FW
  RTM -->|"0.0.0.0/0<br/>next hop: 10.189.129.196 または network.egressNextHopIp"| FW
  FW --> NET
```

## 通信制御フロー（NSG）

以下は、サブネット間の許可通信（NSG 受信規則）を可視化した図です。

```mermaid
flowchart LR
  AG["ApplicationGatewaySubnet<br/>10.189.129.0/25"]
  U["UserNodeSubnet<br/>10.189.128.0/24<br/>NSG: usernode"]
  N["AgentNodeSubnet<br/>10.189.130.64/26<br/>NSG: agentnode"]
  P["PrivateEndpointSubnet<br/>10.189.130.0/26<br/>NSG: pep"]
  M["MaintenanceSubnet<br/>10.189.130.128/29<br/>NSG: maint"]
  B["AzureBastionSubnet<br/>10.189.129.128/26"]
  ACT["ActionGroup"]

  AG -->|"TCP 8080,3000,3080 許可"| U
  AG -->|"TCP 8080,3000,3080 許可"| N
  U -->|"TCP 443,4443 許可"| U
  U -->|"TCP 443,4443 許可"| N
  N -->|"TCP 443,4443 許可"| U
  N -->|"TCP 443,4443 許可"| N
  M -->|"Any 許可"| U
  M -->|"Any 許可"| N
  U -->|"Any 許可"| P
  N -->|"Any 許可"| P
  M -->|"Any 許可"| P
  ACT -->|"TCP 8080 許可"| U
  ACT -->|"TCP 8080 許可"| N
  B -->|"TCP 22,3389 許可"| M
```

# ルートテーブル

## アウトバウンド通信

ハブ&スポーク構成などで **集約された FW 経由のアウトバウンド**が必要な場合、  
`infra/common.parameter.json`の`network.egressNextHopIp` に IP を指定すると **ユーザー定義ルート (UDR)** が作成されます。  
これにより AKS からの外向き通信経路を制御できます。  
`network.egressNextHopIp` を指定しない場合は[設置したFirewallのプライベートIP]をインターネット向けアウトバウンド通信のネクストホップとして指定します。

- ゲートウェイルート伝搬（BGP ルート伝搬）は `network.enableGatewayRoutePropagation` で制御します。
  - `false`（デフォルト）: 無効
  - `true`: 有効
- 推奨値は `false`（無効）です。
- 理由:
  - UDR で定義した next hop を常に優先し、意図しない BGP 経路混入を防止するため
  - ハブ側 ExpressRoute / VPN Gateway の経路広告による予期せぬ経路変更を避けるため
  - 通信障害時の切り分けを単純化し、経路の再現性を高めるため

## インバウンド通信

TLS検査を有効化するためApplication GatewayからAzure Firewallを経由させる構成とします。
また、FW を前面に置くと **NAT で送信元が変わり**、AppGW + WAF が **クライアント情報を正しく識別できなくなる**ためです。  
そのため、AppGW + WAF を前面に配置し、FW を経由して AKS に到達する構成にしています。

## rt-[common.environmentName]-[common.systemName]-firewall

Application Gateway Subnet から AKS 宛て通信（UserNodeSubnet / AgentNodeSubnet）を Firewall 経由にするためのルート

ゲートウェイルート伝搬（BGP ルート伝搬）: [network.enableGatewayRoutePropagation]（`false`: 無効 / `true`: 有効、推奨は `false`）

| ルート名                        | アドレスプレフィックス | ネクストホップの種類 | ネクストホップ                     |
| ------------------------------- | ---------------------- | -------------------- | ---------------------------------- |
| udr-usernode-inbound            | `UserNodeSubnet`       | 仮想アプライアンス   | [設置したFirewallのプライベートIP] |
| udr-agentnode-inbound           | `AgentNodeSubnet`      | 仮想アプライアンス   | [設置したFirewallのプライベートIP] |

## rt-[common.environmentName]-[common.systemName]-outbound-aks

AKSからアウトバウンドへの通信

ゲートウェイルート伝搬（BGP ルート伝搬）: [network.enableGatewayRoutePropagation]（`false`: 無効 / `true`: 有効、推奨は `false`）

| ルート名              | アドレスプレフィックス  | ネクストホップの種類 | ネクストホップ                                          |
| --------------------- | ----------------------- | -------------------- | ------------------------------------------------------- |
| udr-appgw-return      | `ApplicationGatewaySubnet` | 仮想アプライアンス   | [設置したFirewallのプライベートIP] |
| udr-internet-outbound | 0.0.0.0/0               | 仮想アプライアンス   | [network.egressNextHopIp] or [設置したFirewallのプライベートIP] |

- `udr-appgw-return` は `UserNodeSubnet` と `AgentNodeSubnet` に適用し、AppGW 宛て戻り通信を本環境 Firewall 経由に固定します。
- `network.egressNextHopIp` が指定されると `udr-internet-outbound` の next hop は集約 FW 側になりますが、`ApplicationGatewaySubnet` 宛てはより長いプレフィックス（ロンゲストマッチ）で `udr-appgw-return` が優先されます。

## rt-[common.environmentName]-[common.systemName]-outbound-maint

MaintenanceSubnet からアウトバウンドへの通信

ゲートウェイルート伝搬（BGP ルート伝搬）: [network.enableGatewayRoutePropagation]（`false`: 無効 / `true`: 有効、推奨は `false`）

| ルート名              | アドレスプレフィックス  | ネクストホップの種類 | ネクストホップ                                          |
| --------------------- | ----------------------- | -------------------- | ------------------------------------------------------- |
| udr-internet-outbound | 0.0.0.0/0               | 仮想アプライアンス   | [network.egressNextHopIp] or [設置したFirewallのプライベートIP] |

# ネットワークセキュリティグループ

## 命名規則

ルールの目的を明確に示すように、わかりやすい名前を付ける。
[Allow/Deny]-[プロトコル]-[From/To]-[ソース/宛先]

## 優先度について

ルールの優先度については、以下ルールに従って優先度範囲ごとに連番で付ける。
| 優先度範囲 | 用途 | 説明 |
|------|------|------|
| 100~199 | 優先ルール　　 | 200番以降のルールよりさらに優先すべきルールがある場合の枠 |
| 200~4095 | カスタムルール | プロダクトごとに必要な通信を都度追加する　　　　　　　 |
| 4096 | 最終拒否　　　 | 上記以外すべての通信を拒否　　　　　　　　　　　　　　 |

## デフォルトルール

以下のルールはリソース作成時に自動的に作成される、編集不可のデフォルトルールを表す。
すべてのリソースに含まれるため、以下ルールを個別に記述しない。

### 受信セキュリティ規則

| ソース      | ソースIPアドレス/CIDR範囲,ソースサービスタグ,ソースアプリケーションのセキュリティグループ | ソースポート範囲 | 宛先        | 宛先IPアドレス/CIDR範囲,宛先サービスタグ,宛先アプリケーションのセキュリティグループ | サービス | 宛先ポート範囲 | プロトコル | アクション | 優先度 | 名前                          | 説明 |
| ----------- | ----------------------------------------------------------------------------------------- | ---------------- | ----------- | ----------------------------------------------------------------------------------- | -------- | -------------- | ---------- | ---------- | ------ | ----------------------------- | ---- |
| Service Tag | VirtualNetwork                                                                            | \*               | Service Tag | VirtualNetwork                                                                      | Custom   | \*             | Any        | 許可       | 65000  | AllowVnetInBound              |      |
| Service Tag | AzureLoadBalancer                                                                         | \*               | Any         | -                                                                                   | Custom   | \*             | Any        | 許可       | 65001  | AllowAzureLoadBalancerInBound |      |
| Any         | -                                                                                         | \*               | Any         | -                                                                                   | Custom   | \*             | Any        | 拒否       | 65500  | DenyAllInBound                |      |

### 送信セキュリティ規則

| ソース      | ソースIPアドレス/CIDR範囲,ソースサービスタグ,ソースアプリケーションのセキュリティグループ | ソースポート範囲 | 宛先        | 宛先IPアドレス/CIDR範囲,宛先サービスタグ,宛先アプリケーションのセキュリティグループ | サービス | 宛先ポート範囲 | プロトコル | アクション | 優先度 | 名前                  | 説明 |
| ----------- | ----------------------------------------------------------------------------------------- | ---------------- | ----------- | ----------------------------------------------------------------------------------- | -------- | -------------- | ---------- | ---------- | ------ | --------------------- | ---- |
| Service Tag | VirtualNetwork                                                                            | \*               | Service Tag | VirtualNetwork                                                                      | Custom   | \*             | Any        | 許可       | 65000  | AllowVnetOutBound     |      |
| Any         | -                                                                                         | \*               | Service Tag | Internet                                                                            | Custom   | \*             | Any        | 許可       | 65001  | AllowInternetOutBound |      |
| Any         | -                                                                                         | \*               | Any         | \*                                                                                  | Custom   | \*             | Any        | 拒否       | 65500  | DenyAllOutBound       |      |

## nsg-[common.environmentName]-[common.systemName]-usernode

### 受信セキュリティ規則

※ 優先度 200 で `UserNodeSubnet` と `AgentNodeSubnet` を許可している理由:
- `UserNodeSubnet` 許可: UserPool 内の Node 同士で内部通信が発生するため。
- `AgentNodeSubnet` 許可: usernode と agentnode 間でも内部通信が発生するため。

| ソース       | ソースIPアドレス/CIDR範囲,ソースサービスタグ | ソースポート範囲 | 宛先 | 宛先IPアドレス/CIDR範囲,宛先サービスタグ | サービス | 宛先ポート範囲 | プロトコル | アクション | 優先度 | 名前                          | 説明                             |
| ------------ | -------------------------------------------- | ---------------- | ---- | ---------------------------------------- | -------- | -------------- | ---------- | ---------- | ------ | ----------------------------- | -------------------------------- |
| IPアドレス　 | `UserNodeSubnet`, `AgentNodeSubnet`          | \*               | Any  | -                                        | Custom   | 443,4443       | TCP        | 許可       | 200    | Allow-HTTPS-From-K8SAPIServer | K8SAPIサーバーからの通信許可     |
| IPアドレス　 | `ApplicationGatewaySubnet`                   | \*               | Any  | -                                        | Custom   | 8080,3000,3080 | TCP        | 許可       | 201    | Allow-HTTP-From-AgwSubnet     | ApplicationGatewayからの通信許可 |
| IPアドレス　 | `MaintenanceSubnet`                          | \*               | Any  | -                                        | Custom   | \*             | Any        | 許可       | 202    | Allow-Any-From-MaintVmSubnet  | メンテナンス用VMからの通信許可   |
| Service Tag  | ActionGroup                                  | \*               | Any  | -                                        | Custom   | 8080           | TCP        | 許可       | 203    | Allow-HTTP-From-ActionGroup   | ログ収集のための通信許可         |
| Any          | -                                            | \*               | Any  | -                                        | Custom   | \*             | Any        | 拒否       | 4096   | DenyAll                       | その他全ての通信拒否             |

## nsg-[common.environmentName]-[common.systemName]-agentnode

### 受信セキュリティ規則

※ 優先度 200 で `UserNodeSubnet` と `AgentNodeSubnet` を許可している理由:
- `AgentNodeSubnet` 許可: agentnode のスケールアウト/再配置時に Node 間の内部通信が発生するため。
- `UserNodeSubnet` 許可: usernode と agentnode 間でも内部通信が発生するため。

| ソース       | ソースIPアドレス/CIDR範囲,ソースサービスタグ | ソースポート範囲 | 宛先 | 宛先IPアドレス/CIDR範囲,宛先サービスタグ | サービス | 宛先ポート範囲 | プロトコル | アクション | 優先度 | 名前                          | 説明                             |
| ------------ | -------------------------------------------- | ---------------- | ---- | ---------------------------------------- | -------- | -------------- | ---------- | ---------- | ------ | ----------------------------- | -------------------------------- |
| IPアドレス　 | `UserNodeSubnet`, `AgentNodeSubnet`          | \*               | Any  | -                                        | Custom   | 443,4443       | TCP        | 許可       | 200    | Allow-HTTPS-From-K8SAPIServer | K8SAPIサーバーからの通信許可     |
| IPアドレス　 | `ApplicationGatewaySubnet`                   | \*               | Any  | -                                        | Custom   | 8080,3000,3080 | TCP        | 許可       | 201    | Allow-HTTP-From-AgwSubnet     | ApplicationGatewayからの通信許可 |
| IPアドレス　 | `MaintenanceSubnet`                          | \*               | Any  | -                                        | Custom   | \*             | Any        | 許可       | 202    | Allow-Any-From-MaintVmSubnet  | メンテナンス用VMからの通信許可   |
| Service Tag  | ActionGroup                                  | \*               | Any  | -                                        | Custom   | 8080           | TCP        | 許可       | 203    | Allow-HTTP-From-ActionGroup   | ログ収集のための通信許可         |
| Any          | -                                            | \*               | Any  | -                                        | Custom   | \*             | Any        | 拒否       | 4096   | DenyAll                       | その他全ての通信拒否             |

## nsg-[common.environmentName]-[common.systemName]-pep

### 受信セキュリティ規則

| ソース       | ソースIPアドレス/CIDR範囲,ソースサービスタグ | ソースポート範囲 | 宛先 | 宛先IPアドレス/CIDR範囲,宛先サービスタグ | サービス | 宛先ポート範囲 | プロトコル | アクション | 優先度 | 名前                         | 説明                           |
| ------------ | -------------------------------------------- | ---------------- | ---- | ---------------------------------------- | -------- | -------------- | ---------- | ---------- | ------ | ---------------------------- | ------------------------------ |
| IPアドレス　 | `UserNodeSubnet`, `AgentNodeSubnet`          | \*               | Any  | -                                        | Custom   | \*             | Any        | 許可       | 200    | Allow-Any-From-AksSubnet     | Aksからの通信許可              |
| IPアドレス　 | `MaintenanceSubnet`                          | \*               | Any  | -                                        | Custom   | \*             | Any        | 許可       | 201    | Allow-Any-From-MaintVmSubnet | メンテナンス用VMからの通信許可 |
| Any          | -                                            | \*               | Any  | -                                        | Custom   | \*             | Any        | 拒否       | 4096   | DenyAll                      | その他全ての通信拒否           |

### 送信セキュリティ規則

| ソース      | ソースIPアドレス/CIDR範囲,ソースサービスタグ,ソースアプリケーションのセキュリティグループ | ソースポート範囲 | 宛先        | 宛先IPアドレス/CIDR範囲,宛先サービスタグ,宛先アプリケーションのセキュリティグループ | サービス | 宛先ポート範囲 | プロトコル | アクション | 優先度 | 名前              | 説明 |
| ----------- | ----------------------------------------------------------------------------------------- | ---------------- | ----------- | ----------------------------------------------------------------------------------- | -------- | -------------- | ---------- | ---------- | ------ | ----------------- | ---- |
| Service Tag | VirtualNetwork                                                                            | \*               | Service Tag | VirtualNetwork                                                                      | Custom   | \*             | Any        | 許可       | 200    | Allow-Any-To-Vnet |      |
| Any         | -                                                                                         | \*               | Any         | \*                                                                                  | Custom   | \*             | Any        | 拒否       | 4096   | Deny-Any-To-All   |      |

## nsg-[common.environmentName]-[common.systemName]-maint

### 受信セキュリティ規則

| ソース       | ソースIPアドレス/CIDR範囲,ソースサービスタグ | ソースポート範囲 | 宛先 | 宛先IPアドレス/CIDR範囲,宛先サービスタグ | サービス | 宛先ポート範囲 | プロトコル | アクション | 優先度 | 名前                         | 説明                         |
| ------------ | -------------------------------------------- | ---------------- | ---- | ---------------------------------------- | -------- | -------------- | ---------- | ---------- | ------ | ---------------------------- | ---------------------------- |
| IPアドレス　 | [network.sharedBastionIp] または [AzureBastionSubnet] | \*               | Any  | -                                        | Custom   | 22,3389        | TCP        | 許可       | 200    | Allow-SSH-RDP-From-BastionServer | 踏み台からの SSH/RDP 通信許可 |
| Any          | -                                            | \*               | Any  | -                                        | Custom   | \*             | Any        | 拒否       | 4096   | DenyAll                      | その他全ての通信拒否         |

`network.sharedBastionIp` は IP または CIDR（例: `10.0.10.0/24`）で指定可能です。指定した場合は [network.sharedBastionIp] からの通信を許可し、未指定の場合は [AzureBastionSubnet] からの通信を許可します。
