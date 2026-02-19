# Azure Cache for Redis

## Azure Cache for Redis 本体

| 項目 | 設定値 | Bicepプロパティ名 |
| --- | --- | --- |
| 名前 | redis-[common.environmentName]-[common.systemName] | name |
| 場所 | [common.location] | location |
| SKU | Premium (例) | sku.name |
| SKU Family | P (例) | sku.family |
| 容量 | 1 (例) | sku.capacity |
| TLS 最小バージョン | 1.2 | properties.minimumTlsVersion |
| 非 TLS ポート | false | properties.enableNonSslPort |
| パブリックアクセス | Disabled | properties.publicNetworkAccess |

## 診断設定

- 診断設定は有効化します（`allLogs` / `AllMetrics`）。
- 実装時は、利用するリソースプロバイダーでサポートされるカテゴリに合わせて設定します。

## 削除ロック

- Redis / Private Endpoint / Private DNS ゾーンに削除ロックを適用します。

## リソース命名規則

- CAF の省略形ルールに準拠し、Azure Cache for Redis は `redis` を利用します。
- そのため命名は `redis-[common.environmentName]-[common.systemName]` を基本とします。
- 文字数制約（1〜63文字）を超える場合は、`environmentName` / `systemName` を短縮して調整します。

参考:

- Azure CAF Resource Abbreviations
  - https://learn.microsoft.com/ja-jp/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

## 認証・アクセス方針

- 認証キー（Primary/Secondary Key）または Microsoft Entra 認証を利用します。
- アプリ接続は `6380/TLS` を前提とします（非 TLS ポートは無効）。
- 詳細な権限設計（ロール・ID 付与）は、要件確定後に追記します。

## データ構成作成方針

- 本設計では、Azure Cache for Redis 本体までを IaC 対象とします。
- キー設計、TTL 設計、名前空間設計、アプリ側キャッシュ戦略は **IaC 対象外** とし、
  デプロイ後にアプリ実装・運用設計で管理します。

## ネットワーク方針

- `publicNetworkAccess=Disabled` を前提とし、Private Endpoint 経由で接続します。
- Private Endpoint は `PrivateEndpointSubnet` に配置します。
- `docs/infra/network.md` の NSG/UDR 方針に従います。

## Private Endpoint

| 項目 | 設定値 | Bicepプロパティ名 |
| --- | --- | --- |
| 名前 | pep-redis-[common.environmentName]-[common.systemName] | name |
| 場所 | [common.location] | location |
| プライベートリンク接続名 | pep-redis-[common.environmentName]-[common.systemName] | properties.privateLinkServiceConnections.name |
| プライベートリンク対象ID | id(redis-[common.environmentName]-[common.systemName]) | properties.privateLinkServiceConnections.properties.privateLinkServiceId |
| グループID | redisCache | properties.privateLinkServiceConnections.properties.groupIds |
| サブネットID | vnet-[common.environmentName]-[common.systemName]/PrivateEndpointSubnet | properties.subnet.id |

## NSG（PrivateEndpointSubnet）方針

- Redis Private Endpoint 宛ては AKS サブネットからのみ許可します。
- 許可ソースは `UserNodeSubnet` と `AgentNodeSubnet` の両方です。
- 宛先ポートは `6380/TCP` を許可対象とします。
- 受信規則は `docs/infra/network.md` の `nsg-[common.environmentName]-[common.systemName]-pep` に従います。

## Private DNS ゾーン

`network.enableCentralizedPrivateDns` を使って、ゾーン作成の有無を制御します。

- `false`（デフォルト）: 集約 DNS なし。環境内で `privatelink.redis.cache.windows.net` を作成して利用
- `true`: 集約 DNS あり。環境内でのゾーン作成はスキップし、集約側 DNS（ハブ側）で管理されたゾーンを利用

| 項目 | 設定値 | Bicepプロパティ名 |
| --- | --- | --- |
| 名前 | privatelink.redis.cache.windows.net | name |
| 場所 | global | location |

## DNS ゾーングループ

PEP と Private DNS ゾーンを紐づけるリソース。

- `network.enableCentralizedPrivateDns=false` の場合: 作成します
- `network.enableCentralizedPrivateDns=true` の場合: 環境内ゾーンを作成しないため、DNS ゾーングループも作成しません

| 項目 | 設定値 | Bicepプロパティ名 |
| --- | --- | --- |
| 親 | pep-redis-[common.environmentName]-[common.systemName] | parent |
| 名前 | dnszg-redis-[common.environmentName]-[common.systemName] | name |
| プライベートDNSゾーン構成名 | privatelink-redis-cache-windows-net | properties.privateDnsZoneConfigs.name |
| プライベートDNSゾーンID | id(privatelink.redis.cache.windows.net) | properties.privateDnsZoneConfigs.properties.privateDnsZoneId |

## 仮想ネットワークリンク

- `network.enableCentralizedPrivateDns=false` の場合: 作成します
- `network.enableCentralizedPrivateDns=true` の場合: 環境内ゾーンを作成しないため、仮想ネットワークリンクも作成しません

| 項目 | 設定値 | Bicepプロパティ名 |
| --- | --- | --- |
| 親 | privatelink.redis.cache.windows.net | parent |
| 名前 | link-redis-to-vnet-[common.environmentName]-[common.systemName] | name |
| 場所 | global | location |
| 自動登録 | false | properties.registrationEnabled |
| 仮想ネットワークID | id(vnet-[common.environmentName]-[common.systemName]) | properties.virtualNetwork.id |

## 運用保護項目（要件に応じて選択）

- メンテナンスウィンドウの固定化
- バックアップ/復旧方針（必要な場合）

## 未確定項目（実装前に決定）

- SKU/性能（レベル、容量、スケール方針）
- 可用性要件（ゾーン冗長・冗長構成の要否）
- 認証方式（Access Key / Entra）
- 運用時の接続元（AKS のみ / メンテVM含む）
