# Azure FireWall

- ※[]内は`infra/common.parameter.json`の設定値に従って設定されます。

## 基本

| 項目       | 設定値                              | Bicepプロパティ名         |
| ---------- | ----------------------------------- | ------------------------- |
| 名前       | afw-[environmentName]-[systemName]  | name                      |
| 場所       | [location]                          | location                  |
| FWポリシー | afwp-[environmentName]-[systemName] | properties.FirewallPolicy |

## IP構成

| 項目                   | 設定値                                     | Bicepプロパティ名                                         |
| ---------------------- | ------------------------------------------ | --------------------------------------------------------- |
| 名前                   | ipconf-afw-[environmentName]-[systemName]  | properties.IpConfigurations.name                          |
| パブリックIPアドレスID | id(pip-afw-[environmentName]-[systemName]) | properties.IpConfigurations.properties.publicIPAddress.id |
| サブネットID           | id(AzureFirewallSubnet)                    | properties.IpConfigurations.properties.subnet.id          |

# Azure FireWall Policy

## 基本

| 項目                 | 設定値                              | Bicepプロパティ名          |
| -------------------- | ----------------------------------- | -------------------------- |
| 名前                 | afwp-[environmentName]-[systemName] | name                       |
| 場所                 | [location]                          | location                   |
| 脅威インテリジェンス | Deny                                | properties.threatIntelMode |

## SKU

| 項目   | 設定値                                                                | Bicepプロパティ名   |
| ------ | --------------------------------------------------------------------- | ------------------- |
| サイズ | `enableFirewallIdps=true` の場合は Premium、`false` の場合は Standard | properties.sku.tier |

## 侵入検知

| 項目   | 設定値 | Bicepプロパティ名                  |
| ------ | ------ | ---------------------------------- |
| モード | Alert  | properties.intrusionDetection.mode |

# パブリックIPアドレス

| IPアドレス名                           | 概要                 |
| -------------------------------------- | -------------------- |
| pip-afw-[environmentName]-[systemName] | ファイヤーウォール用 |

##　基本
| 項目 | 設定値 | Bicepプロパティ名 |
|------|------|------|
| 名前 | pip-afw-[environmentName]-[systemName] | name |
| 場所 | [location] | location |
| sku | Standard | sku.name |
| IPアドレス割り当て方法 | Static | properties.publicIPAllocationMethod |
| IPアドレスバージョン | IPv4 | properties.publicIPAddressVersion |
| DDOS保護 | `enableDdosProtection=true` の場合は Enabled、`false` の場合は Disabled | properties.ddosSettings.protectionMode |
