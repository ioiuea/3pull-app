// ###########################################
// 02_network (phase 1): VNET & Subnets
// ###########################################
targetScope = 'subscription'

// ###########################################
// 共通パラメータ
// ###########################################

@description('環境名')
param environmentName string = loadJsonContent('../../../common.parameter.json').environmentName

@description('現在日時')
param currentDateTime string = utcNow('yyyyMMddTHHmmss')

@description('デプロイ先リージョン')
param location string = loadJsonContent('../../../common.parameter.json').location

@description('システム名称')
param systemName string = loadJsonContent('../../../common.parameter.json').systemName

@description('ログアナリティクス名')
param logAnalyticsName string = 'log-${environmentName}-${systemName}'
param logAnalyticsResourceGroupName string = 'rg-${environmentName}-${systemName}-monitor'

// ###########################################
// モジュール共通パラメータ
// ###########################################

@description('モジュール群')
param modulesName string = 'nw'

@description('タグ情報')
param modulesTags object = {
  environmentName: environmentName
  systemName: systemName
  modulesName: modulesName
  createdBy: 'bicep'
  billing: 'infra'
}

@description('VNETの名称')
param vnetName string = 'vnet-${environmentName}-${systemName}'

@description('VNETのアドレスプレフィックス')
param vnetAddressPrefixes array = loadJsonContent('../../../common.parameter.json').vnetAddressPrefixes

@description('VNETのDNSサーバー')
param vnetDnsServers array = []

@description('サブネット情報')
param subnets array

@description('ロック')
param lockKind string = 'CanNotDelete'

// ###########################################
// モジュールの定義
// ###########################################

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-${environmentName}-${systemName}-${modulesName}'
  location: location
  tags: modulesTags
}

module virtualNetworkModule './modules/virtualNetwork.bicep' = {
  name: 'vnet-${currentDateTime}'
  scope: resourceGroup
  params: {
    location: location
    modulesTags: modulesTags
    virtualNetworkName: vnetName
    addressPrefixes: vnetAddressPrefixes
    dnsServers: vnetDnsServers
    lockKind: lockKind
    logAnalyticsName: logAnalyticsName
    logAnalyticsResourceGroupName: logAnalyticsResourceGroupName
  }
}

@batchSize(1)
module subnetCreateModule './modules/subnet.bicep' = [
  for (subnet, i) in subnets: {
    name: 'subnet-create-${currentDateTime}-${subnet.name}'
    scope: resourceGroup
    params: {
      virtualNetworkName: vnetName
      subnetName: subnet.name
      addressPrefix: subnet.addressPrefix
      networkSecurityGroupId: ''
      routeTableId: ''
    }
    dependsOn: [
      virtualNetworkModule
    ]
  }
]

output resourceGroupScope object = resourceGroup
output vnetScope object = virtualNetworkModule.outputs.virtualNetworkScope
