# AzureKubernetesService

- ※[]内は`infra/common.parameter.json`の設定値に従って設定されます。

| AKS名                              | 概要                |
| ---------------------------------- | ------------------- |
| aks-[environmentName]-[systemName] | アプリデプロイ用AKS |

## 基本

| 項目            | 設定値                                 | Bicepプロパティ名     |
| --------------- | -------------------------------------- | --------------------- |
| 名前            | aks-[environmentName]-[systemName]     | name                  |
| 場所            | [location]                             | location              |
| ID              | SystemAssigned                         | identity.type         |
| DNSプレフィクス | aks-dns-[environmentName]-[systemName] | properties.dnsPrefix  |
| RBACの有効化    | true                                   | properties.enableRBAC |

## エージェントプール

| 項目             | 設定値                                                  | Bicepプロパティ名                              |
| ---------------- | ------------------------------------------------------- | ---------------------------------------------- |
| 名前             | agentpool                                               | properties.agentPoolProfiles.name              |
| OSディスクサイズ | 0                                                       | properties.agentPoolProfiles.osDiskSizeGB      |
| VMサイズ         | standard_d2s_v4                                         | properties.agentPoolProfiles.vmSize            |
| 可用性ゾーン     | 1,2,3                                                   | properties.agentPoolProfiles.avalavilityZones  |
| OSタイプ         | Linux                                                   | properties.agentPoolProfiles.osType            |
| モード           | System                                                  | properties.agentPoolProfiles.mode              |
| カウント         | 3                                                       | properties.agentPoolProfiles.count             |
| 最小VM数         | 3                                                       | properties.agentPoolProfiles.minCount          |
| 最大VM数         | 6                                                       | properties.agentPoolProfiles.maxCount          |
| 自動スケーリング | true                                                    | properties.agentPoolProfiles.enableAutoScaling |
| サブネットID     | id(vnet-[environmentName]-[systemName]/AgentNodeSubnet) | properties.agentPoolProfiles.vnetSubnetID      |

## ユーザープール

| 項目             | 設定値                                                 | Bicepプロパティ名                              |
| ---------------- | ------------------------------------------------------ | ---------------------------------------------- |
| 名前             | userpool                                               | properties.agentPoolProfiles.name              |
| OSディスクサイズ | 0                                                      | properties.agentPoolProfiles.osDiskSizeGB      |
| VMサイズ         | [aksUserPoolVmSize]                                    | properties.agentPoolProfiles.vmSize            |
| 可用性ゾーン     | 1,2,3                                                  | properties.agentPoolProfiles.avalavilityZones  |
| OSタイプ         | Linux                                                  | properties.agentPoolProfiles.osType            |
| モード           | User                                                   | properties.agentPoolProfiles.mode              |
| カウント         | [aksUserPoolCount]                                     | properties.agentPoolProfiles.count             |
| 最小VM数         | [aksUserPoolMinCount]                                  | properties.agentPoolProfiles.minCount          |
| 最大VM数         | [aksUserPoolMaxCount]                                  | properties.agentPoolProfiles.maxCount          |
| 自動スケーリング | true                                                   | properties.agentPoolProfiles.enableAutoScaling |
| サブネットID     | id(vnet-[environmentName]-[systemName]/UserNodeSubnet) | properties.agentPoolProfiles.vnetSubnetID      |
| ラベル           | pool: [aksUserPoolLabel]                               | properties.agentPoolProfiles.nodeLabels        |

## アドオン：Azureポリシー

| 項目   | 設定値 | Bicepプロパティ名                            |
| ------ | ------ | -------------------------------------------- |
| 有効化 | true   | properties.addonProfiles.azurepolicy.enabled |

## アドオン：イングレスコントローラー

| 項目   | 設定値                                      | Bicepプロパティ名                                                              |
| ------ | ------------------------------------------- | ------------------------------------------------------------------------------ |
| 有効化 | true                                        | properties.addonProfiles.ingressApplicationGateway.enabled                     |
| AGWID  | id(agw-[environmentName]-[systemName]-agic) | properties.addonProfiles.ingressApplicationGateway.config.applicationGatewayId |

## AAD情報

| 項目                  | 設定値 | Bicepプロパティ名                     |
| --------------------- | ------ | ------------------------------------- |
| RBACの有効化          | true   | properties.aadProfile.enableAzureRBAC |
| マネージドAADの有効化 | true   | properties.aadProfile.managed         |

## ネットワーク情報

| 項目                         | 設定値                                      | Bicepプロパティ名                           |
| ---------------------------- | ------------------------------------------- | ------------------------------------------- |
| ネットワークプラグイン       | azure                                       | properties.networkProfile.networkPlugin     |
| ネットワークポリシー         | azure                                       | properties.networkProfile.networkPolicy     |
| ネットワークプラグインモード | overlay                                     | properties.networkProfile.networkPluginMode |
| ロードバランサ―SKU           | standard                                    | properties.networkPraofile.loadBalancerSku  |
| ポッドCIDR                   | [aksPodCidr]                                | properties.networkProfile.podCidr           |
| サービスCIDR                 | [aksServiceCidr]                            | properties.networkProfile.serviceCidr       |
| DNSサービスIP                | [aksServiceCidrのレンジの10個目のIP]        | properties.networkProfile.dnsServiceIP      |

※ ポッドCIDRはVNETのIPアドレスレンジとは別空間のため、`infra/common.parameter.json` の `aksPodCidr` で任意指定

## 自動アップグレード情報

| 項目               | 設定値 | Bicepプロパティ名                            |
| ------------------ | ------ | -------------------------------------------- |
| 自動アップグレード | patch  | properties.autoUpgradeProfile.upgradeChannel |

## APIサーバーアクセス情報

| 項目                                               | 設定値 | Bicepプロパティ名                                                |
| -------------------------------------------------- | ------ | ---------------------------------------------------------------- |
| プライベートクラスター有効化                       | true   | properties.apiServerAccessProfile.enablePrivateCluster           |
| プライベートクラスター用追加パブリックFQDNの有効化 | false  | properties.apiServerAccessProfile.enablePrivateClusterPublicFQDN |
