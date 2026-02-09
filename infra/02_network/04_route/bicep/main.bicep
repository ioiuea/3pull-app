// ###########################################
// 02_network (phase 4): Route Table & Subnet Attach
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
param logAnalyticsName string = 'log-${environmentName}-${systemName}-app'
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
  category: 'common'
}

@description('VNETの名称')
param vnetName string = 'vnet-${environmentName}-${systemName}-app'

@description('サブネット情報')
param subnets array

@description('Route Table 定義')
param routeTables array = []

@description('サブネットと Route Table の対応表')
param subnetRouteTableMap object = {}

@description('Firewall のプライベート IP')
param firewallPrivateIp string

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

module agicToFirewallRouteTable './modules/routeTable.bicep' = {
  name: 'rt-${currentDateTime}-firewall'
  scope: resourceGroup
  params: {
    location: location
    modulesTags: modulesTags
    routeTableName: 'rt-${environmentName}-${systemName}-firewall'
    routes: [
      {
        name: 'udr-agic-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

@batchSize(1)
module subnetAttachModule './modules/subnet.bicep' = [
  for (subnet, i) in subnets: if (subnet.name != 'AzureFirewallSubnet') {
    name: 'subnet-attach-${currentDateTime}-${subnet.name}'
    scope: resourceGroup
    params: {
      virtualNetworkName: vnetName
      subnetName: subnet.name
      addressPrefix: subnet.addressPrefix
      networkSecurityGroupId: resourceId(
        subscription().subscriptionId,
        resourceGroup.name,
        'Microsoft.Network/networkSecurityGroups',
        'nsg-${environmentName}-${systemName}-${subnet.alias}'
      )
      routeTableId: contains(subnetRouteTableMap, subnet.alias)
        ? resourceId(
            subscription().subscriptionId,
            resourceGroup.name,
            'Microsoft.Network/routeTables',
            'rt-${environmentName}-${systemName}-${subnetRouteTableMap[subnet.alias]}'
          )
        : (subnet.alias == 'agic' ? agicToFirewallRouteTable.outputs.routeTableId : '')
    }
    dependsOn: [
      routeTableModule
      agicToFirewallRouteTable
    ]
  }
]
