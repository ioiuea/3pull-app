@description('VNET名')
param virtualNetworkName string

@description('サブネット名')
param subnetName string

@description('アドレスプレフィックス')
param addressPrefix string

@description('NSG ID')
param networkSecurityGroupId string = ''

@description('ルートテーブル ID')
param routeTableId string = ''

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: '${virtualNetworkName}/${subnetName}'
  properties: {
    addressPrefix: addressPrefix
    networkSecurityGroup: empty(networkSecurityGroupId)
      ? null
      : {
          id: networkSecurityGroupId
        }
    routeTable: empty(routeTableId)
      ? null
      : {
          id: routeTableId
        }
  }
}

output subnetScope object = subnet
output subnetName string = subnet.name
output subnetId string = subnet.id
