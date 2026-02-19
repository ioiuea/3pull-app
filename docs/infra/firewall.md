# Azure FireWall

- ※[]内は`infra/common.parameter.json`の設定値に従って設定されます。

## 基本

| 項目       | 設定値                              | Bicepプロパティ名         |
| ---------- | ----------------------------------- | ------------------------- |
| 名前       | afw-[common.environmentName]-[common.systemName]  | name                      |
| 場所       | [common.location]                   | location                  |
| FWポリシー | afwp-[common.environmentName]-[common.systemName] | properties.FirewallPolicy |

## IP構成

| 項目                   | 設定値                                     | Bicepプロパティ名                                         |
| ---------------------- | ------------------------------------------ | --------------------------------------------------------- |
| 名前                   | ipconf-afw-[common.environmentName]-[common.systemName]  | properties.IpConfigurations.name                          |
| パブリックIPアドレスID | id(pip-afw-[common.environmentName]-[common.systemName]) | properties.IpConfigurations.properties.publicIPAddress.id |
| サブネットID           | id(AzureFirewallSubnet)                    | properties.IpConfigurations.properties.subnet.id          |

# Azure FireWall Policy

## 基本

| 項目                 | 設定値                              | Bicepプロパティ名          |
| -------------------- | ----------------------------------- | -------------------------- |
| 名前                 | afwp-[common.environmentName]-[common.systemName] | name                       |
| 場所                 | [common.location]                   | location                   |
| 脅威インテリジェンス | Deny                                | properties.threatIntelMode |

## SKU

| 項目   | 設定値                                                                | Bicepプロパティ名   |
| ------ | --------------------------------------------------------------------- | ------------------- |
| サイズ | `network.enableFirewallIdps=true` の場合は Premium、`false` の場合は Standard | properties.sku.tier |

## 侵入検知

| 項目   | 設定値 | Bicepプロパティ名                  |
| ------ | ------ | ---------------------------------- |
| モード | Alert  | properties.intrusionDetection.mode |

# パブリックIPアドレス

| IPアドレス名                           | 概要                 |
| -------------------------------------- | -------------------- |
| pip-afw-[common.environmentName]-[common.systemName] | ファイヤーウォール用 |

##　基本
| 項目 | 設定値 | Bicepプロパティ名 |
|------|------|------|
| 名前 | pip-afw-[common.environmentName]-[common.systemName] | name |
| 場所 | [common.location] | location |
| sku | Standard | sku.name |
| IPアドレス割り当て方法 | Static | properties.publicIPAllocationMethod |
| IPアドレスバージョン | IPv4 | properties.publicIPAddressVersion |
| DDOS保護 | `network.enableDdosProtection=true` の場合は Enabled、`false` の場合は Disabled | properties.ddosSettings.protectionMode |
