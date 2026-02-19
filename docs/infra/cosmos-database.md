# Azure Cosmos DB（NoSQL API）

## Cosmos DB アカウント本体

| 項目                   | 設定値                                             | Bicepプロパティ名                       |
| ---------------------- | -------------------------------------------------- | --------------------------------------- |
| 名前                   | cosno-[common.environmentName]-[common.systemName] | name                                    |
| 場所                   | [common.location]                                  | location                                |
| API 種別               | NoSQL (SQL API)                                    | kind / properties.capabilities          |
| SKU                    | Standard                                           | properties.databaseAccountOfferType     |
| パブリックアクセス     | Disabled                                           | properties.publicNetworkAccess          |
| 自動フェールオーバー   | [要件に応じて設定]                                 | properties.enableAutomaticFailover      |
| 複数リージョン書き込み | [要件に応じて設定]                                 | properties.enableMultipleWriteLocations |

## 診断設定

- 診断設定は有効化します（`allLogs` / `AllMetrics`）。
- 実装時は、利用するリソースプロバイダーでサポートされるカテゴリに合わせて設定します。

## 削除ロック

- Cosmos アカウント / Private Endpoint / Private DNS ゾーンに削除ロックを適用します。

## リソース命名規則

- CAF 準拠の省略形を利用します。
  - `Microsoft.DocumentDB/databaseAccounts`（Cosmos DB account for NoSQL）: `cosno`
  - `Microsoft.DocumentDB/databaseAccounts/sqlDatabases`（NoSQL API の DB 論理リソース）: `cosmos`
- そのため、アカウント名は `cosno-[common.environmentName]-[common.systemName]` を基本とします。
- 文字数制約（3〜44文字）を超える場合は `environmentName` / `systemName` を短縮して調整します。

参考:

- Azure CAF Resource Abbreviations
  - https://learn.microsoft.com/ja-jp/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

## データベース名 / コンテナ名（論理リソース）

この設計では、データベースおよびコンテナは **IaCの構築対象外** とします。  
Cosmos DB アカウントのみを IaC で作成し、データベース名・コンテナ名・パーティションキー・スループットは
デプロイ後に Azure Portal または運用手順で作成/設定します。

| 項目               | 設定方針                                               |
| ------------------ | ------------------------------------------------------ |
| データベース名     | デプロイ後に運用者が作成                               |
| コンテナ名         | デプロイ後に運用者が作成                               |
| パーティションキー | コンテナ作成時にアプリ要件で設定                       |
| スループット       | 手動 / Autoscale / Serverless を運用方針に合わせて設定 |

## 認証・アクセス方針

- 本番用途ではキー直接配布を避け、Managed Identity + RBAC を優先します。
- 必要に応じて `disableLocalAuth=true` を検討します。
- Data Plane RBAC（Cosmos DB Built-in Data Reader/Contributor など）は、デプロイ後に Azure Portal / IaC で付与します。

## ネットワーク方針

- `publicNetworkAccess=Disabled` を前提とし、Private Endpoint 経由で接続します。
- Private Endpoint は `PrivateEndpointSubnet` に配置します。
- `docs/infra/network.md` の NSG/UDR 方針に従います。

## Private Endpoint

| 項目                     | 設定値                                                                  | Bicepプロパティ名                                                        |
| ------------------------ | ----------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| 名前                     | pep-cosno-[common.environmentName]-[common.systemName]                  | name                                                                     |
| 場所                     | [common.location]                                                       | location                                                                 |
| プライベートリンク接続名 | pep-cosno-[common.environmentName]-[common.systemName]                  | properties.privateLinkServiceConnections.name                            |
| プライベートリンク対象ID | id(cosno-[common.environmentName]-[common.systemName])                  | properties.privateLinkServiceConnections.properties.privateLinkServiceId |
| グループID               | Sql                                                                     | properties.privateLinkServiceConnections.properties.groupIds             |
| サブネットID             | vnet-[common.environmentName]-[common.systemName]/PrivateEndpointSubnet | properties.subnet.id                                                     |

## NSG（PrivateEndpointSubnet）方針

- Cosmos DB Private Endpoint 宛ては AKS サブネットからのみ許可します。
- 許可ソースは `UserNodeSubnet` と `AgentNodeSubnet` の両方です。
- 宛先ポートは `443/TCP` を許可対象とします。
- 受信規則は `docs/infra/network.md` の `nsg-[common.environmentName]-[common.systemName]-pep` に従います。

## Private DNS ゾーン

`network.enableCentralizedPrivateDns` を使って、ゾーン作成の有無を制御します。

- `false`（デフォルト）: 集約 DNS なし。環境内で `privatelink.documents.azure.com` を作成して利用
- `true`: 集約 DNS あり。環境内でのゾーン作成はスキップし、集約側 DNS（ハブ側）で管理されたゾーンを利用

| 項目 | 設定値                          | Bicepプロパティ名 |
| ---- | ------------------------------- | ----------------- |
| 名前 | privatelink.documents.azure.com | name              |
| 場所 | global                          | location          |

## DNS ゾーングループ

PEP と Private DNS ゾーンを紐づけるリソース。

- `network.enableCentralizedPrivateDns=false` の場合: 作成します
- `network.enableCentralizedPrivateDns=true` の場合: 環境内ゾーンを作成しないため、DNS ゾーングループも作成しません

| 項目                        | 設定値                                                   | Bicepプロパティ名                                            |
| --------------------------- | -------------------------------------------------------- | ------------------------------------------------------------ |
| 親                          | pep-cosno-[common.environmentName]-[common.systemName]   | parent                                                       |
| 名前                        | dnszg-cosno-[common.environmentName]-[common.systemName] | name                                                         |
| プライベートDNSゾーン構成名 | privatelink-documents-azure-com                          | properties.privateDnsZoneConfigs.name                        |
| プライベートDNSゾーンID     | id(privatelink.documents.azure.com)                      | properties.privateDnsZoneConfigs.properties.privateDnsZoneId |

## 仮想ネットワークリンク

- `network.enableCentralizedPrivateDns=false` の場合: 作成します
- `network.enableCentralizedPrivateDns=true` の場合: 環境内ゾーンを作成しないため、仮想ネットワークリンクも作成しません

| 項目               | 設定値                                                          | Bicepプロパティ名              |
| ------------------ | --------------------------------------------------------------- | ------------------------------ |
| 親                 | privatelink.documents.azure.com                                 | parent                         |
| 名前               | link-cosno-to-vnet-[common.environmentName]-[common.systemName] | name                           |
| 場所               | global                                                          | location                       |
| 自動登録           | false                                                           | properties.registrationEnabled |
| 仮想ネットワークID | id(vnet-[common.environmentName]-[common.systemName])           | properties.virtualNetwork.id   |

## 運用保護項目（要件に応じて選択）

- バックアップポリシー（連続バックアップ or 定期バックアップ）
- キー管理方式（カスタマーマネージドキーの採用有無）
- 多地域構成（DR 要件）

## 未確定項目（実装前に決定）

- API 種別（NoSQL / MongoDB / Cassandra / Gremlin / Table）
- SQL Database / Container の命名とパーティション設計
- スループット方式（手動 / Autoscale / Serverless）
- バックアップ方式と保持要件
- アクセス制御方式（RBAC / キーベース / Local Auth 無効化）
