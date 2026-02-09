@description('デプロイ先リージョン')
param location string

@description('タグ情報')
param modulesTags object

@description('ロック')
param lockKind string

@description('パブリックIP名')
param publicIPName string

@description('パブリックIPのsku')
param publicIPSku string

@description('パブリックIPの割り当て方法')
param publicIPAllocationMethod string

@description('パブリックIPのバージョン')
param publicIPAddressVersion string

@description('DDOS保護')
param protectionMode string

resource publicIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: publicIPName
  location: location
  tags: modulesTags
  sku: {
    name: publicIPSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    publicIPAddressVersion: publicIPAddressVersion
    ddosSettings: {
      protectionMode: protectionMode
    }
  }
}

resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (lockKind != '') {
  name: 'del-lock-${publicIPName}'
  scope: publicIP
  properties: {
    level: lockKind
  }
}

output publicIPScope object = publicIP
output publicIPName string = publicIP.name
output publicIPId string = publicIP.id
output publicIPResourceGroupName string = resourceGroup().name
output publicIPLocation string = publicIP.location
output publicIPTags object = publicIP.tags
