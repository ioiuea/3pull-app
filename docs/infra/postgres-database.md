# Azure Database for PostgreSQL Flexible Server

## PostgreSQL Flexible Server 本体

| 項目                 | 設定値                                            | Bicepプロパティ名                      |
| -------------------- | ------------------------------------------------- | -------------------------------------- |
| 名前                 | psql-[common.environmentName]-[common.systemName] | name                                   |
| 場所                 | [common.location]                                 | location                               |
| バージョン           | 16 (例)                                           | properties.version                     |
| SKU                  | Standard_D2ds_v5 (例)                             | sku.name                               |
| ストレージサイズ     | 128 GiB (例)                                      | properties.storage.storageSizeGB       |
| バックアップ保持日数 | 7〜35日 (例: 14)                                  | properties.backup.backupRetentionDays  |
| 可用性ゾーン         | [要件に応じて設定]                                | properties.availabilityZone            |
| パブリックアクセス   | Disabled                                          | properties.network.publicNetworkAccess |

## 診断設定

- 診断設定は有効化します（`allLogs` / `AllMetrics`）。
- 実装時は、利用するリソースプロバイダーでサポートされるカテゴリに合わせて設定します。

## 削除ロック

- サーバー / Private Endpoint / Private DNS ゾーンに削除ロックを適用します。

## リソース命名規則

- CAF の省略形ルールに準拠し、PostgreSQL は `psql` を利用します。
- そのため命名は `psql-[common.environmentName]-[common.systemName]` を基本とします。
- 文字数制約（3〜63文字）を超える場合は、`environmentName` / `systemName` を短縮して調整します。

参考:

- Azure CAF Resource Abbreviations
  - https://learn.microsoft.com/ja-jp/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

## 認証・アクセス方針

- PostgreSQL 管理者アカウント（`administratorLogin` / `administratorLoginPassword`）を利用します。
- Microsoft Entra 認証や DB ロールの詳細設計は、要件確定後に追記します。
- アプリ接続ユーザーの作成・権限付与は、デプロイ後の初期化手順で実施します。

## データベース / スキーマ作成方針

- 本設計では、PostgreSQL Flexible Server 本体までを IaC 対象とします。
- データベース、スキーマ、テーブル、ロール/権限設定は **IaC 対象外** とし、
  デプロイ後に運用手順（SQL 実行・マイグレーション）で作成します。
- 既存のアプリ実装方針（Drizzle / Alembic など）に合わせて、スキーマ管理責務を分離します。

## ネットワーク方針

- `publicNetworkAccess=Disabled` を前提とし、Private Endpoint 経由で接続します。
- Private Endpoint は `PrivateEndpointSubnet` に配置します。
- `docs/infra/network.md` の NSG/UDR 方針に従います。

## Private Endpoint

| 項目                     | 設定値                                                                  | Bicepプロパティ名                                                        |
| ------------------------ | ----------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| 名前                     | pep-psql-[common.environmentName]-[common.systemName]                   | name                                                                     |
| 場所                     | [common.location]                                                       | location                                                                 |
| プライベートリンク接続名 | pep-psql-[common.environmentName]-[common.systemName]                   | properties.privateLinkServiceConnections.name                            |
| プライベートリンク対象ID | id(psql-[common.environmentName]-[common.systemName])                   | properties.privateLinkServiceConnections.properties.privateLinkServiceId |
| グループID               | postgresqlServer                                                        | properties.privateLinkServiceConnections.properties.groupIds             |
| サブネットID             | vnet-[common.environmentName]-[common.systemName]/PrivateEndpointSubnet | properties.subnet.id                                                     |

## NSG（PrivateEndpointSubnet）方針

- PostgreSQL Private Endpoint 宛ては AKS サブネットからのみ許可します。
- 許可ソースは `UserNodeSubnet` と `AgentNodeSubnet` の両方です。
- 宛先ポートは `5432/TCP` を許可対象とします。
- 受信規則は `docs/infra/network.md` の `nsg-[common.environmentName]-[common.systemName]-pep` に従います。

## Private DNS ゾーン

`network.enableCentralizedPrivateDns` を使って、ゾーン作成の有無を制御します。

- `false`（デフォルト）: 集約 DNS なし。環境内で `privatelink.postgres.database.azure.com` を作成して利用
- `true`: 集約 DNS あり。環境内でのゾーン作成はスキップし、集約側 DNS（ハブ側）で管理されたゾーンを利用

| 項目 | 設定値                                  | Bicepプロパティ名 |
| ---- | --------------------------------------- | ----------------- |
| 名前 | privatelink.postgres.database.azure.com | name              |
| 場所 | global                                  | location          |

## DNS ゾーングループ

PEP と Private DNS ゾーンを紐づけるリソース。

- `network.enableCentralizedPrivateDns=false` の場合: 作成します
- `network.enableCentralizedPrivateDns=true` の場合: 環境内ゾーンを作成しないため、DNS ゾーングループも作成しません

| 項目                        | 設定値                                                  | Bicepプロパティ名                                            |
| --------------------------- | ------------------------------------------------------- | ------------------------------------------------------------ |
| 親                          | pep-psql-[common.environmentName]-[common.systemName]   | parent                                                       |
| 名前                        | dnszg-psql-[common.environmentName]-[common.systemName] | name                                                         |
| プライベートDNSゾーン構成名 | privatelink-postgres-database-azure-com                 | properties.privateDnsZoneConfigs.name                        |
| プライベートDNSゾーンID     | id(privatelink.postgres.database.azure.com)             | properties.privateDnsZoneConfigs.properties.privateDnsZoneId |

## 仮想ネットワークリンク

- `network.enableCentralizedPrivateDns=false` の場合: 作成します
- `network.enableCentralizedPrivateDns=true` の場合: 環境内ゾーンを作成しないため、仮想ネットワークリンクも作成しません

| 項目               | 設定値                                                         | Bicepプロパティ名              |
| ------------------ | -------------------------------------------------------------- | ------------------------------ |
| 親                 | privatelink.postgres.database.azure.com                        | parent                         |
| 名前               | link-psql-to-vnet-[common.environmentName]-[common.systemName] | name                           |
| 場所               | global                                                         | location                       |
| 自動登録           | false                                                          | properties.registrationEnabled |
| 仮想ネットワークID | id(vnet-[common.environmentName]-[common.systemName])          | properties.virtualNetwork.id   |

## 運用保護項目（要件に応じて選択）

- 高可用性（HA）
- PITR を考慮したバックアップ保持日数
- メンテナンスウィンドウの固定化

## 未確定項目（実装前に決定）

- SKU/性能（vCore, メモリ, IOPS）
- バックアップ保持日数
- HA の有無
- Entra 認証の有無
- 運用時の接続元（AKS のみ / メンテVM含む）
