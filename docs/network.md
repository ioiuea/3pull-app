# 仮想ネットワーク

- ※[]内は`infra/common.parameter.json`の設定値に従って設定されます。

| 仮想ネットワーク名                  | リソースグループ名                   | 場所       | アドレス空間          | DNSサーバー | DDoS Protection                                 | DDoS保護プラン                                                        |
| ----------------------------------- | ------------------------------------ | ---------- | --------------------- | ----------- | ----------------------------------------------- | --------------------------------------------------------------------- |
| vnet-[environmentName]-[systemName] | rg-[environmentName]-[systemName]-nw | [location] | [vnetAddressPrefixes] | [vnetDnsServers] 未指定時は Azure提供、指定時は指定DNSサーバー | [enableDdosProtection] に応じて有効/無効        | [enableDdosProtection] と [ddosProtectionPlanId] に応じて既存利用/新規作成/未適用 |

- ※ `enableDdosProtection=true` の場合
  - `ddosProtectionPlanId` 指定あり: 指定した既存 DDoS 保護プランを適用
  - `ddosProtectionPlanId` 未指定: DDoS 保護プランを新規作成して適用
- ※ `enableDdosProtection=false` の場合
  - DDoS 保護プランは作成せず、VNET への DDoS Protection 適用もしません
- ※ `vnetDnsServers` 未指定（空配列）の場合は Azure 提供 DNS を利用し、指定した場合はその DNS サーバーを利用します。
- ※ ハブ&スポーク構成で集約 DNS を利用する場合、ハブ側 Firewall のプライベート IP など、到達可能な DNS サーバー IP を指定します。
- ※最低限、以下のいずれかのアドレスレンジが必要です。
  - `/24` が 3 つ分
  - 連続するサブネットレンジを確保できる場合は `/23` が 1 つ分 + `/24` が 1 つ分、もしくは `/22` が 1 つ分（`/24` 3 つ分相当）

# サブネット

| サブネット名               | プレフィクス | サービスエンドポイント | NSG名                                        | ルートテーブル名                           | 備考                                   |
| -------------------------- | ------------ | ---------------------- | -------------------------------------------- | ------------------------------------------ | -------------------------------------- |
| `UserNodeSubnet`           | `/24`        |                        | nsg-[environmentName]-[systemName]-usernode  | rt-[environmentName]-[systemName]-outbound-aks | アプリデプロイ領域                     |
| `ApplicationGatewaySubnet` | `/25`        |                        |                                              | rt-[environmentName]-[systemName]-firewall | AGIC用サブネット                       |
| `AgentNodeSubnet`          | `/26`        |                        | nsg-[environmentName]-[systemName]-agentnode | rt-[environmentName]-[systemName]-outbound-aks | AKSのエージェントノード用サブネット    |
| `PrivateEndpointSubnet`    | `/26`        |                        | nsg-[environmentName]-[systemName]-pep       |                                            | プライベートエンドポイント用サブネット |
| `AzureFirewallSubnet`      | `/26`        |                        |                                              |                                            | ファイヤーウォール用サブネット         |
| `AzureBastionSubnet`       | `/26`        |                        |                                              |                                            | Bastion用サブネット（`sharedBastionIp` 未指定時のみ） |
| `MaintenanceSubnet`        | `/29`        |                        | nsg-[environmentName]-[systemName]-maint     | rt-[environmentName]-[systemName]-outbound-maint | メンテVM用サブネット                   |

※ 以下のサブネットへのネットワークセキュリティグループの設定はAzure非推奨であり予期せぬエラーが発生する可能性があるため設定しません。

- `AzureFirewallSubnet`
- `ApplicationGatewaySubnet`
- `AzureBastionSubnet`

# 構成図（生成パラメータ例）

以下は `infra/log/tmp-*-20260215T120923.json` を基にした構成図です。

```mermaid
flowchart TB
  Internet[(Internet)]
  ActionGroup[(ActionGroup)]

  subgraph VNet["vnet (10.189.70.0/24, 10.189.71.0/24, 10.189.72.0/24, 10.189.73.0/24)"]
    U["UserNodeSubnet\n10.189.70.0/24\nNSG: nsg-dev-3pull-usernode\nRT: rt-dev-3pull-outbound-aks"]
    A["ApplicationGatewaySubnet\n10.189.71.0/25\nRT: rt-dev-3pull-firewall"]
    B["AzureBastionSubnet\n10.189.71.128/26"]
    F["AzureFirewallSubnet\n10.189.71.192/26\nFirewall IP: 10.189.71.193"]
    P["PrivateEndpointSubnet\n10.189.72.0/26\nNSG: nsg-dev-3pull-pep"]
    G["AgentNodeSubnet\n10.189.72.64/26\nNSG: nsg-dev-3pull-agentnode\nRT: rt-dev-3pull-outbound-aks"]
    M["MaintenanceSubnet\n10.189.72.128/29\nNSG: nsg-dev-3pull-maint\nRT: rt-dev-3pull-outbound-maint"]
  end

  RTFW["rt-dev-3pull-firewall\nudr-usernode-inbound / udr-agentnode-inbound\nUserNodeSubnet/AgentNodeSubnet -> 10.189.71.193"]
  RTOAKS["rt-dev-3pull-outbound-aks\nudr-appgw-return: ApplicationGatewaySubnet -> 10.189.71.193\nudr-internet-outbound: 0.0.0.0/0 -> 10.189.71.193 or egressNextHopIp"]
  RTOM["rt-dev-3pull-outbound-maint\nudr-internet-outbound: 0.0.0.0/0 -> 10.189.71.193 or egressNextHopIp"]

  A --- RTFW
  U --- RTOAKS
  G --- RTOAKS
  M --- RTOM

  B -->|"22,3389"| M
  A -->|"8080,3000,3080"| U
  A -->|"8080,3000,3080"| G
  M -->|"any"| U
  M -->|"any"| G
  U -->|"any"| P
  M -->|"any"| P
  ActionGroup -->|"8080"| U
  ActionGroup -->|"8080"| G
  RTOAKS --> F
  RTOM --> F
  RTFW --> F
```

# ルートテーブル

## アウトバウンド通信

ハブ&スポーク構成などで **集約された FW 経由のアウトバウンド**が必要な場合、  
`infra/common.parameter.json`の`egressNextHopIp` に IP を指定すると **ユーザー定義ルート (UDR)** が作成されます。  
これにより AKS からの外向き通信経路を制御できます。  
`egressNextHopIp` を指定しない場合は[設置したFirewallのプライベートIP]をインターネット向けアウトバウンド通信のネクストホップとして指定します。

- 設計方針として、`egressNextHopIp` の指定有無に関わらず、`outbound-aks` / `outbound-maint` のルートテーブルでは **ゲートウェイルート伝搬（BGP ルート伝搬）を無効化** します。
- 理由:
  - UDR で定義した next hop を常に優先し、意図しない BGP 経路混入を防止するため
  - ハブ側 ExpressRoute / VPN Gateway の経路広告による予期せぬ経路変更を避けるため
  - 通信障害時の切り分けを単純化し、経路の再現性を高めるため

## インバウンド通信

TLS検査を有効化するためApplication GatewayからAzure Firewallを経由させる構成とします。
また、FW を前面に置くと **NAT で送信元が変わり**、AppGW + WAF が **クライアント情報を正しく識別できなくなる**ためです。  
そのため、AppGW + WAF を前面に配置し、FW を経由して AKS に到達する構成にしています。

## rt-[environmentName]-[systemName]-firewall

Application Gateway Subnet から AKS 宛て通信（UserNodeSubnet / AgentNodeSubnet）を Firewall 経由にするためのルート

ゲートウェイルート伝搬（BGP ルート伝搬）: 無効

| ルート名                        | アドレスプレフィックス | ネクストホップの種類 | ネクストホップ                     |
| ------------------------------- | ---------------------- | -------------------- | ---------------------------------- |
| udr-usernode-inbound            | `UserNodeSubnet`       | 仮想アプライアンス   | [設置したFirewallのプライベートIP] |
| udr-agentnode-inbound           | `AgentNodeSubnet`      | 仮想アプライアンス   | [設置したFirewallのプライベートIP] |

## rt-[environmentName]-[systemName]-outbound-aks

AKSからアウトバウンドへの通信

ゲートウェイルート伝搬（BGP ルート伝搬）: 無効

| ルート名              | アドレスプレフィックス  | ネクストホップの種類 | ネクストホップ                                          |
| --------------------- | ----------------------- | -------------------- | ------------------------------------------------------- |
| udr-appgw-return      | `ApplicationGatewaySubnet` | 仮想アプライアンス   | [設置したFirewallのプライベートIP] |
| udr-internet-outbound | 0.0.0.0/0               | 仮想アプライアンス   | [egressNextHopIp] or [設置したFirewallのプライベートIP] |

- `udr-appgw-return` は `UserNodeSubnet` と `AgentNodeSubnet` に適用し、AppGW 宛て戻り通信を本環境 Firewall 経由に固定します。
- `egressNextHopIp` が指定されると `udr-internet-outbound` の next hop は集約 FW 側になりますが、`ApplicationGatewaySubnet` 宛てはより長いプレフィックス（ロンゲストマッチ）で `udr-appgw-return` が優先されます。

## rt-[environmentName]-[systemName]-outbound-maint

MaintenanceSubnet からアウトバウンドへの通信

ゲートウェイルート伝搬（BGP ルート伝搬）: 無効

| ルート名              | アドレスプレフィックス  | ネクストホップの種類 | ネクストホップ                                          |
| --------------------- | ----------------------- | -------------------- | ------------------------------------------------------- |
| udr-internet-outbound | 0.0.0.0/0               | 仮想アプライアンス   | [egressNextHopIp] or [設置したFirewallのプライベートIP] |

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

## nsg-[environmentName]-[systemName]-usernode

### 受信セキュリティ規則

| ソース       | ソースIPアドレス/CIDR範囲,ソースサービスタグ | ソースポート範囲 | 宛先 | 宛先IPアドレス/CIDR範囲,宛先サービスタグ | サービス | 宛先ポート範囲 | プロトコル | アクション | 優先度 | 名前                          | 説明                             |
| ------------ | -------------------------------------------- | ---------------- | ---- | ---------------------------------------- | -------- | -------------- | ---------- | ---------- | ------ | ----------------------------- | -------------------------------- |
| IPアドレス　 | `UserNodeSubnet`, `AgentNodeSubnet`          | \*               | Any  | -                                        | Custom   | 443,4443       | TCP        | 許可       | 200    | Allow-HTTPS-From-K8SAPIServer | K8SAPIサーバーからの通信許可     |
| IPアドレス　 | `ApplicationGatewaySubnet`                   | \*               | Any  | -                                        | Custom   | 8080,3000,3080 | TCP        | 許可       | 201    | Allow-HTTP-From-AgwSubnet     | ApplicationGatewayからの通信許可 |
| IPアドレス　 | `MaintenanceSubnet`                          | \*               | Any  | -                                        | Custom   | \*             | Any        | 許可       | 202    | Allow-Any-From-MaintVmSubnet  | メンテナンス用VMからの通信許可   |
| Service Tag  | ActionGroup                                  | \*               | Any  | -                                        | Custom   | 8080           | TCP        | 許可       | 203    | Allow-HTTP-From-ActionGroup   | ログ収集のための通信許可         |
| Any          | -                                            | \*               | Any  | -                                        | Custom   | \*             | Any        | 拒否       | 4096   | DenyAll                       | その他全ての通信拒否             |

## nsg-[environmentName]-[systemName]-agentnode

### 受信セキュリティ規則

| ソース       | ソースIPアドレス/CIDR範囲,ソースサービスタグ | ソースポート範囲 | 宛先 | 宛先IPアドレス/CIDR範囲,宛先サービスタグ | サービス | 宛先ポート範囲 | プロトコル | アクション | 優先度 | 名前                          | 説明                             |
| ------------ | -------------------------------------------- | ---------------- | ---- | ---------------------------------------- | -------- | -------------- | ---------- | ---------- | ------ | ----------------------------- | -------------------------------- |
| IPアドレス　 | `UserNodeSubnet`, `AgentNodeSubnet`          | \*               | Any  | -                                        | Custom   | 443,4443       | TCP        | 許可       | 200    | Allow-HTTPS-From-K8SAPIServer | K8SAPIサーバーからの通信許可     |
| IPアドレス　 | `ApplicationGatewaySubnet`                   | \*               | Any  | -                                        | Custom   | 8080,3000,3080 | TCP        | 許可       | 201    | Allow-HTTP-From-AgwSubnet     | ApplicationGatewayからの通信許可 |
| IPアドレス　 | `MaintenanceSubnet`                          | \*               | Any  | -                                        | Custom   | \*             | Any        | 許可       | 202    | Allow-Any-From-MaintVmSubnet  | メンテナンス用VMからの通信許可   |
| Service Tag  | ActionGroup                                  | \*               | Any  | -                                        | Custom   | 8080           | TCP        | 許可       | 203    | Allow-HTTP-From-ActionGroup   | ログ収集のための通信許可         |
| Any          | -                                            | \*               | Any  | -                                        | Custom   | \*             | Any        | 拒否       | 4096   | DenyAll                       | その他全ての通信拒否             |

## nsg-[environmentName]-[systemName]-pep

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

## nsg-[environmentName]-[systemName]-maint

### 受信セキュリティ規則

| ソース       | ソースIPアドレス/CIDR範囲,ソースサービスタグ | ソースポート範囲 | 宛先 | 宛先IPアドレス/CIDR範囲,宛先サービスタグ | サービス | 宛先ポート範囲 | プロトコル | アクション | 優先度 | 名前                         | 説明                         |
| ------------ | -------------------------------------------- | ---------------- | ---- | ---------------------------------------- | -------- | -------------- | ---------- | ---------- | ------ | ---------------------------- | ---------------------------- |
| IPアドレス　 | [sharedBastionIp] または [AzureBastionSubnet] | \*               | Any  | -                                        | Custom   | 22,3389        | TCP        | 許可       | 200    | Allow-SSH-RDP-From-BastionServer | 踏み台からの SSH/RDP 通信許可 |
| Any          | -                                            | \*               | Any  | -                                        | Custom   | \*             | Any        | 拒否       | 4096   | DenyAll                      | その他全ての通信拒否         |

`sharedBastionIp` は IP または CIDR（例: `10.0.10.0/24`）で指定可能です。指定した場合は [sharedBastionIp] からの通信を許可し、未指定の場合は [AzureBastionSubnet] からの通信を許可します。
