// ###########################################
// 02_network (phase 3): Route Table & Subnet Attach
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

@description('ログアナリティクスのリソースグループ名')
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

@description('サブネット情報（ルート・NSG反映用）')
param subnets array

@description('NSG定義')
param nsgs array = []

@description('Route Table 定義')
param routeTables array = []

@description('ロック')
param lockKind string = 'CanNotDelete'

// ###########################################
// モジュールの定義
// ###########################################

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: 'rg-${environmentName}-${systemName}-${modulesName}'
}

module routeTableModule './modules/routeTable.bicep' = [
  for routeTable in routeTables: {
    name: 'rt-${currentDateTime}-${routeTable.name}'
    scope: resourceGroup
    params: {
      location: location
      modulesTags: modulesTags
      routeTableName: 'rt-${environmentName}-${systemName}-${routeTable.name}'
      routes: routeTable.routes
    }
  }
]

module networkSecurityGroupModule './modules/networkSecurityGroup.bicep' = [
  for nsg in nsgs: {
    name: 'nsg-${currentDateTime}-${nsg.subnetName}'
    scope: resourceGroup
    params: {
      location: location
      modulesTags: modulesTags
      lockKind: lockKind
      networkSecurityGroupName: 'nsg-${environmentName}-${systemName}-${nsg.subnetName}'
      securityRules: nsg.securityRules
      logAnalyticsName: logAnalyticsName
      logAnalyticsResourceGroupName: logAnalyticsResourceGroupName
    }
  }
]

@batchSize(1)
module subnetAttachModule './modules/subnet.bicep' = [
  for (subnet, i) in subnets: if (subnet.name != 'AzureFirewallSubnet') {
    name: 'subnet-attach-${currentDateTime}-${subnet.name}'
    scope: resourceGroup
    params: {
      virtualNetworkName: vnetName
      subnetName: subnet.name
      addressPrefix: subnet.addressPrefix
      networkSecurityGroupId: empty(subnet.networkSecurityGroupName)
        ? ''
        : resourceId(
            subscription().subscriptionId,
            resourceGroup.name,
            'Microsoft.Network/networkSecurityGroups',
            subnet.networkSecurityGroupName
          )
      routeTableId: empty(subnet.routeTableName)
        ? ''
        : resourceId(
            subscription().subscriptionId,
            resourceGroup.name,
            'Microsoft.Network/routeTables',
            subnet.routeTableName
          )
    }
    dependsOn: [
      routeTableModule
      networkSecurityGroupModule
    ]
  }
]
