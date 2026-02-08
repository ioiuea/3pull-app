// ###########################################
// 02_network : DNSゾーン & Subnet & Route Table & NSG & Diagnostic Settings
// ###########################################
targetScope = 'subscription'

// ###########################################
// 共通パラメータ
// ###########################################

@description('環境名')
param environmentName string = loadJsonContent('../../common.parameter.json').environmentName

@description('現在日時')
param currentDateTime string = utcNow('yyyyMMddTHHmmss')

@description('デプロイ先リージョン')
param location string = loadJsonContent('../../common.parameter.json').location

@description('システム名称')
param systemName string = loadJsonContent('../../common.parameter.json').systemName

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

@description('VNETのアドレスプレフィックス')
param vnetAddressPrefixes array = loadJsonContent('../../common.parameter.json').vnetAddressPrefixes

@description('VNETのDNSサーバー')
param vnetDnsServers array = []

@description('NSG定義')
param nsgs array = []

@description('サブネット情報')
param subnets array

@description('Route Table 定義')
param routeTables array = []

@description('サブネットと Route Table の対応表')
param subnetRouteTableMap object = {}

// @description('Route Table 定義')
// param routeTables array = []

@description('ロック')
param lockKind string = 'CanNotDelete'

// ###########################################
// NetworkSecurityGroup パラメータ
// ###########################################

// @description('NSGの情報')
// param nsgInfo object
// param nsgInfoList array = nsgInfo.networkSecurityGroupList

// ###########################################
// Routeテーブル パラメータ
// ###########################################

// @description('ルートテーブルの情報')
// param rtInfo object
// param rtInfoList array = rtInfo.routeTableList

// ###########################################
// Subnet パラメータ
// ###########################################

// サブネットのアドレスプレフィックス情報は環境で異なるため、
// パラメータファイル（snet.parameter.json）で定義する
// @description('IPアドレスプレフィックスの情報')
// param addressPrefix object

// 基盤チームで払い出される既存VNETへ複数のサブネットを作成する制約があり、
// パラメータファイルで配列定義してfor文ループで処理するとVNETリソースで競合が発生する
// dependsOnを利用して順番にサブネットを作成することも不可能なため、
// 各サブネットの情報を個別に定義しサブネットモジュールを呼び出す
// サブネット情報を追加した場合はモジュールの定義も追加すること
// @description('agent-aksのサブネット情報')
// param agentAksSuffix string = 'agent-aks'
// param agentAksAddressPrefix string = addressPrefix.agentAksAddressPrefix
// param agentAksNsgSuffix string = 'agent-aks'
// param agentAksRouteTableSuffix string = ''
// param agentAksServiceEndpoints object = {
//   serviceEndpoints: [
//     { service: 'Microsoft.CognitiveServices' }
//   ]
// }
// param agentAksDelegations array = []
// param agentAksPrivateEndpointNetworkPolicies string = 'Enabled'
// param agentAksPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('web-aksのサブネット情報')
// param webAksSuffix string = 'web-aks'
// param webAksAddressPrefix string = addressPrefix.webAksAddressPrefix
// param webAksNsgSuffix string = 'web-aks'
// param webAksRouteTableSuffix string = ''
// param webAksServiceEndpoints object = {
//   serviceEndpoints: [
//     { service: 'Microsoft.CognitiveServices' }
//   ]
// }
// param webAksDelegations array = []
// param webAksPrivateEndpointNetworkPolicies string = 'Enabled'
// param webAksPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('mcp-aksのサブネット情報')
// param mcpAksSuffix string = 'mcp-aks'
// param mcpAksAddressPrefix string = addressPrefix.mcpAksAddressPrefix
// param mcpAksNsgSuffix string = 'mcp-aks'
// param mcpAksRouteTableSuffix string = ''
// param mcpAksServiceEndpoints object = {
//   serviceEndpoints: [
//     { service: 'Microsoft.CognitiveServices' }
//   ]
// }
// param mcpAksDelegations array = []
// param mcpAksPrivateEndpointNetworkPolicies string = 'Enabled'
// param mcpAksPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('cre8-aksのサブネット情報')
// param cre8AksSuffix string = 'cre8-aks'
// param cre8AksAddressPrefix string = addressPrefix.cre8AksAddressPrefix
// param cre8AksNsgSuffix string = 'cre8-aks'
// param cre8AksRouteTableSuffix string = ''
// param cre8AksServiceEndpoints object = {
//   serviceEndpoints: [
//     { service: 'Microsoft.CognitiveServices' }
//   ]
// }
// param cre8AksDelegations array = []
// param cre8AksPrivateEndpointNetworkPolicies string = 'Enabled'
// param cre8AksPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('crawl-aksのサブネット情報')
// param crawlAksSuffix string = 'crawl-aks'
// param crawlAksAddressPrefix string = addressPrefix.crawlAksAddressPrefix
// param crawlAksNsgSuffix string = 'crawl-aks'
// param crawlAksRouteTableSuffix string = ''
// param crawlAksServiceEndpoints object = {
//   serviceEndpoints: [
//     { service: 'Microsoft.CognitiveServices' }
//   ]
// }
// param crawlAksDelegations array = []
// param crawlAksPrivateEndpointNetworkPolicies string = 'Enabled'
// param crawlAksPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('system-aksのサブネット情報')
// param systemAksSuffix string = 'system-aks'
// param systemAksAddressPrefix string = addressPrefix.systemAksAddressPrefix
// param systemAksNsgSuffix string = 'system-aks'
// param systemAksRouteTableSuffix string = ''
// param systemAksServiceEndpoints object = {
//   serviceEndpoints: [
//     { service: 'Microsoft.CognitiveServices' }
//   ]
// }
// param systemAksDelegations array = []
// param systemAksPrivateEndpointNetworkPolicies string = 'Enabled'
// param systemAksPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('app-agwのサブネット情報')
// param appAgwSuffix string = 'app-agw'
// param appAgwAddressPrefix string = addressPrefix.appAgwAddressPrefix
// param appAgwNsgSuffix string = 'app-agw'
// param appAgwRouteTableSuffix string = 'firewall'
// param appAgwServiceEndpoints object = {
//   serviceEndpoints: []
// }
// param appAgwDelegations array = []
// param appAgwPrivateEndpointNetworkPolicies string = 'Enabled'
// param appAgwPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('agent-apimのサブネット情報')
// param agentApimSuffix string = 'agent-apim'
// param agentApimAddressPrefix string = addressPrefix.agentApim
// param agentApimNsgSuffix string = 'agent-apim'
// param agentApimRouteTableSuffix string = ''
// param agentApimServiceEndpoints object = {
//   serviceEndpoints: []
// }
// param agentApimDelegations array = []
// param agentApimPrivateEndpointNetworkPolicies string = 'Enabled'
// param agentApimPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('agent-apim-injectionのサブネット情報')
// param agentApimInjectionSuffix string = 'agent-apim-injection'
// param agentApimInjectionAddressPrefix string = addressPrefix.agentApimInjection
// param agentApimInjectionNsgSuffix string = 'agent-apim-injection'
// param agentApimInjectionRouteTableSuffix string = ''
// param agentApimInjectionServiceEndpoints object = {
//   serviceEndpoints: []
// }
// param agentApimInjectionDelegations array = [
//   {
//     name: 'Microsoft.Web/serverfarms'
//     properties: {
//       serviceName: 'Microsoft.Web/serverfarms'
//     }
//   }
// ]
// param agentApimInjectionPrivateEndpointNetworkPolicies string = 'Enabled'
// param agentApimInjectionPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('pepのサブネット情報')
// param pepSuffix string = 'pep'
// param pepAddressPrefix string = addressPrefix.pepAddressPrefix
// param pepNsgSuffix string = 'pep'
// param pepRouteTableSuffix string = ''
// param pepServiceEndpoints object = {
//   serviceEndpoints: [
//     { service: 'Microsoft.Storage' }
//     { service: 'Microsoft.CognitiveServices' }
//   ]
// }
// param pepDelegations array = []
// param pepPrivateEndpointNetworkPolicies string = 'Enabled'
// param pepPrivateLinkServiceNetworkPolicies string = 'Disabled'

// // firewallのサブネットは名称が固定されているため直接指定
// @description('firewallのサブネット情報')
// param firewallSubnetName string = 'AzureFirewallSubnet'
// param firewallSuffix string = 'firewall'
// param firewallAddressPrefix string = addressPrefix.firewallAddressPrefix
// param firewallNsgSuffix string = ''
// param firewallRouteTableSuffix string = ''
// param firewallServiceEndpoints object = {
//   serviceEndpoints: []
// }
// param firewallDelegations array = []
// param firewallPrivateEndpointNetworkPolicies string = 'Enabled'
// param firewallPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('maintのサブネット情報')
// param maintSuffix string = 'maint'
// param maintAddressPrefix string = addressPrefix.maintAddressPrefix
// param maintNsgSuffix string = 'maint'
// param maintRouteTableSuffix string = ''
// param maintServiceEndpoints object = {
//   serviceEndpoints: []
// }
// param maintDelegations array = []
// param maintPrivateEndpointNetworkPolicies string = 'Enabled'
// param maintPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('bastionのサブネット情報')
// param bastionSuffix string = 'bastion'
// param bastionAddressPrefix string = addressPrefix.bastionAddressPrefix
// param bastionNsgSuffix string = 'bastion'
// param bastionRouteTableSuffix string = ''
// param bastionServiceEndpoints object = {
//   serviceEndpoints: []
// }
// param bastionDelegations array = []
// param bastionPrivateEndpointNetworkPolicies string = 'Enabled'
// param bastionPrivateLinkServiceNetworkPolicies string = 'Disabled'

// @description('proxyのサブネット情報')
// param proxySuffix string = 'proxy'
// param proxyAddressPrefix string = addressPrefix.proxyAddressPrefix
// param proxyNsgSuffix string = 'proxy'
// param proxyRouteTableSuffix string = 'outbound'
// param proxyServiceEndpoints object = {
//   serviceEndpoints: []
// }
// param proxyDelegations array = []
// param proxyPrivateEndpointNetworkPolicies string = 'Enabled'
// param proxyPrivateLinkServiceNetworkPolicies string = 'Disabled'

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

module networkSecurityGroupModule './modules/networkSecurityGroup.bicep' = [
  for (nsg, i) in nsgs: {
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

@batchSize(1)
module subnetModule './modules/subnet.bicep' = [
  for (subnet, i) in subnets: {
    name: 'subnet-${currentDateTime}-${subnet.name}'
    scope: resourceGroup
    params: {
      virtualNetworkName: vnetName
      subnetName: 'snet-${environmentName}-${systemName}-${subnet.name}'
      addressPrefix: subnet.addressPrefix
      networkSecurityGroupId: resourceId(
        subscription().subscriptionId,
        resourceGroup.name,
        'Microsoft.Network/networkSecurityGroups',
        'nsg-${environmentName}-${systemName}-${subnet.name}'
      )
      routeTableId: contains(subnetRouteTableMap, subnet.name)
        ? resourceId(
            subscription().subscriptionId,
            resourceGroup.name,
            'Microsoft.Network/routeTables',
            'rt-${environmentName}-${systemName}-${subnetRouteTableMap[subnet.name]}'
          )
        : ''
    }
    dependsOn: [
      virtualNetworkModule
      networkSecurityGroupModule
      routeTableModule
    ]
  }
]

// resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
//   name: virtualNetworkModule.outputs.virtualNetworkName
//   scope: resourceGroup
// }

// module networkSecurityGroupModule '../modules/networkSecurityGroup.bicep' = [
//   for nsg in nsgInfoList: {
//     name: 'networkSecurityGroup-${currentDateTime}-${nsg.useSuffix}'
//     scope: resourceGroup
//     params: {
//       location: location
//       modulesTags: modulesTags
//       lockKind: lockKind
//       networkSecurityGroupName: 'nsg-${environmentName}-${systemName}-${nsg.useSuffix}'
//       securityRules: nsg.networkSecurityRules
//       logAnalyticsName: logAnalyticsName
//       logAnalyticsResourceGroupName: logAnalyticsResourceGroupName
//     }
//   }
// ]

// module routeTableModule '../modules/routeTable.bicep' = [
//   for rt in rtInfoList: {
//     name: 'routeTable-${currentDateTime}-${rt.useSuffix}'
//     scope: resourceGroup
//     params: {
//       location: location
//       modulesTags: modulesTags
//       routeTableName: 'rt-${environmentName}-${systemName}-${rt.useSuffix}'
//       routeTableInfo: rt
//       lockKind: lockKind
//     }
//   }
// ]

// module agentAksSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${agentAksSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${agentAksSuffix}'
//     addressPrefix: agentAksAddressPrefix
//     nsgName: empty(agentAksNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${agentAksNsgSuffix}'
//     routeTableName: empty(agentAksRouteTableSuffix)
//       ? ''
//       : 'rt-${environmentName}-${systemName}-${agentAksRouteTableSuffix}'
//     serviceEndpoints: agentAksServiceEndpoints.serviceEndpoints
//     delegations: agentAksDelegations
//     privateEndpointNetworkPolicies: agentAksPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: agentAksPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     networkSecurityGroupModule
//     routeTableModule
//   ]
// }

// module webAksSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${webAksSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${webAksSuffix}'
//     addressPrefix: webAksAddressPrefix
//     nsgName: empty(webAksNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${webAksNsgSuffix}'
//     routeTableName: empty(webAksRouteTableSuffix) ? '' : 'rt-${environmentName}-${systemName}-${webAksRouteTableSuffix}'
//     serviceEndpoints: webAksServiceEndpoints.serviceEndpoints
//     delegations: webAksDelegations
//     privateEndpointNetworkPolicies: webAksPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: webAksPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     agentAksSubnetModule
//   ]
// }

// module mcpAksSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${mcpAksSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${mcpAksSuffix}'
//     addressPrefix: mcpAksAddressPrefix
//     nsgName: empty(mcpAksNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${mcpAksNsgSuffix}'
//     routeTableName: empty(mcpAksRouteTableSuffix) ? '' : 'rt-${environmentName}-${systemName}-${mcpAksRouteTableSuffix}'
//     serviceEndpoints: mcpAksServiceEndpoints.serviceEndpoints
//     delegations: mcpAksDelegations
//     privateEndpointNetworkPolicies: mcpAksPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: mcpAksPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     webAksSubnetModule
//   ]
// }

// module cre8AksSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${cre8AksSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${cre8AksSuffix}'
//     addressPrefix: cre8AksAddressPrefix
//     nsgName: empty(cre8AksNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${cre8AksNsgSuffix}'
//     routeTableName: empty(cre8AksRouteTableSuffix) ? '' : 'rt-${environmentName}-${systemName}-${cre8AksRouteTableSuffix}'
//     serviceEndpoints: cre8AksServiceEndpoints.serviceEndpoints
//     delegations: cre8AksDelegations
//     privateEndpointNetworkPolicies: cre8AksPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: cre8AksPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     mcpAksSubnetModule
//   ]
// }

// module crawlAksSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${crawlAksSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${crawlAksSuffix}'
//     addressPrefix: crawlAksAddressPrefix
//     nsgName: empty(crawlAksNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${crawlAksNsgSuffix}'
//     routeTableName: empty(crawlAksRouteTableSuffix) ? '' : 'rt-${environmentName}-${systemName}-${crawlAksRouteTableSuffix}'
//     serviceEndpoints: crawlAksServiceEndpoints.serviceEndpoints
//     delegations: crawlAksDelegations
//     privateEndpointNetworkPolicies: crawlAksPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: crawlAksPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     cre8AksSubnetModule
//   ]
// }

// module systemAksSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${systemAksSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${systemAksSuffix}'
//     addressPrefix: systemAksAddressPrefix
//     nsgName: empty(systemAksNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${systemAksNsgSuffix}'
//     routeTableName: empty(systemAksRouteTableSuffix) ? '' : 'rt-${environmentName}-${systemName}-${systemAksRouteTableSuffix}'
//     serviceEndpoints: systemAksServiceEndpoints.serviceEndpoints
//     delegations: systemAksDelegations
//     privateEndpointNetworkPolicies: systemAksPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: systemAksPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     cre8AksSubnetModule
//   ]
// }

// module appAgwSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${appAgwSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${appAgwSuffix}'
//     addressPrefix: appAgwAddressPrefix
//     nsgName: empty(appAgwNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${appAgwNsgSuffix}'
//     routeTableName: empty(appAgwRouteTableSuffix)
//       ? ''
//       : 'rt-${environmentName}-${systemName}-${appAgwRouteTableSuffix}'
//     serviceEndpoints: appAgwServiceEndpoints.serviceEndpoints
//     delegations: appAgwDelegations
//     privateEndpointNetworkPolicies: appAgwPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: appAgwPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     crawlAksSubnetModule
//   ]
// }

// module agentApimSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${agentApimSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${agentApimSuffix}'
//     addressPrefix: agentApimAddressPrefix
//     nsgName: empty(agentApimNsgSuffix)
//       ? ''
//       : 'nsg-${environmentName}-${systemName}-${agentApimNsgSuffix}'
//     routeTableName: empty(agentApimRouteTableSuffix)
//       ? ''
//       : 'rt-${environmentName}-${systemName}-${agentApimRouteTableSuffix}'
//     serviceEndpoints: agentApimServiceEndpoints.serviceEndpoints
//     delegations: agentApimDelegations
//     privateEndpointNetworkPolicies: agentApimPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: agentApimPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     appAgwSubnetModule
//   ]
// }

// module agentApimInjectionSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${agentApimInjectionSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${agentApimInjectionSuffix}'
//     addressPrefix: agentApimInjectionAddressPrefix
//     nsgName: empty(agentApimInjectionNsgSuffix)
//       ? ''
//       : 'nsg-${environmentName}-${systemName}-${agentApimInjectionNsgSuffix}'
//     routeTableName: empty(agentApimInjectionRouteTableSuffix)
//       ? ''
//       : 'rt-${environmentName}-${systemName}-${agentApimInjectionRouteTableSuffix}'
//     serviceEndpoints: agentApimInjectionServiceEndpoints.serviceEndpoints
//     delegations: agentApimInjectionDelegations
//     privateEndpointNetworkPolicies: agentApimInjectionPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: agentApimInjectionPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     agentApimSubnetModule
//   ]
// }

// module pepSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${pepSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${pepSuffix}'
//     addressPrefix: pepAddressPrefix
//     nsgName: empty(pepNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${pepNsgSuffix}'
//     routeTableName: empty(pepRouteTableSuffix) ? '' : 'rt-${environmentName}-${systemName}-${pepRouteTableSuffix}'
//     serviceEndpoints: pepServiceEndpoints.serviceEndpoints
//     delegations: pepDelegations
//     privateEndpointNetworkPolicies: pepPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: pepPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     agentApimInjectionSubnetModule
//   ]
// }

// module firewallSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${firewallSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: firewallSubnetName
//     addressPrefix: firewallAddressPrefix
//     nsgName: empty(firewallNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${firewallNsgSuffix}'
//     routeTableName: empty(firewallRouteTableSuffix)
//       ? ''
//       : 'rt-${environmentName}-${systemName}-${firewallRouteTableSuffix}'
//     serviceEndpoints: firewallServiceEndpoints.serviceEndpoints
//     delegations: firewallDelegations
//     privateEndpointNetworkPolicies: firewallPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: firewallPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     pepSubnetModule
//   ]
// }

// module maintSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${maintSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${maintSuffix}'
//     addressPrefix: maintAddressPrefix
//     nsgName: empty(maintNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${maintNsgSuffix}'
//     routeTableName: empty(maintRouteTableSuffix) ? '' : 'rt-${environmentName}-${systemName}-${maintRouteTableSuffix}'
//     serviceEndpoints: maintServiceEndpoints.serviceEndpoints
//     delegations: maintDelegations
//     privateEndpointNetworkPolicies: maintPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: maintPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     firewallSubnetModule
//   ]
// }

// module bastionSubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${bastionSuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${bastionSuffix}'
//     addressPrefix: bastionAddressPrefix
//     nsgName: empty(bastionNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${bastionNsgSuffix}'
//     routeTableName: empty(bastionRouteTableSuffix)
//       ? ''
//       : 'rt-${environmentName}-${systemName}-${bastionRouteTableSuffix}'
//     serviceEndpoints: bastionServiceEndpoints.serviceEndpoints
//     delegations: bastionDelegations
//     privateEndpointNetworkPolicies: bastionPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: bastionPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     maintSubnetModule
//   ]
// }

// module proxySubnetModule '../modules/subnet.bicep' = {
//   name: 'subnet-${currentDateTime}-${proxySuffix}'
//   scope: resourceGroup
//   params: {
//     virtualNetworkName: virtualNetwork.name
//     subnetName: 'snet-${environmentName}-${systemName}-${proxySuffix}'
//     addressPrefix: proxyAddressPrefix
//     nsgName: empty(proxyNsgSuffix) ? '' : 'nsg-${environmentName}-${systemName}-${proxyNsgSuffix}'
//     routeTableName: empty(proxyRouteTableSuffix) ? '' : 'rt-${environmentName}-${systemName}-${proxyRouteTableSuffix}'
//     serviceEndpoints: proxyServiceEndpoints.serviceEndpoints
//     delegations: proxyDelegations
//     privateEndpointNetworkPolicies: proxyPrivateEndpointNetworkPolicies
//     privateLinkServiceNetworkPolicies: proxyPrivateLinkServiceNetworkPolicies
//     lockKind: lockKind
//   }
//   dependsOn: [
//     bastionSubnetModule
//   ]
// }

output resourceGroupScope object = resourceGroup
output vnetScope object = virtualNetworkModule.outputs.virtualNetworkScope
// output dnsZoneScope object = dnsZoneModule.outputs.dnsZoneScope
// output agentAksSubnetScope object = agentAksSubnetModule.outputs.subnetScope
// output webAksSubnetScope object = webAksSubnetModule.outputs.subnetScope
// output mcpAksSubnetScope object = mcpAksSubnetModule.outputs.subnetScope
// output cre8AksSubnetScope object = cre8AksSubnetModule.outputs.subnetScope
// output crawlAksSubnetScope object = crawlAksSubnetModule.outputs.subnetScope
// output systemAksSubnetScope object = systemAksSubnetModule.outputs.subnetScope
// output appAgwSubnetScope object = appAgwSubnetModule.outputs.subnetScope
// output agentApimSubnetScope object = agentApimSubnetModule.outputs.subnetScope
// output agentApimInjectionSubnetScope object = agentApimInjectionSubnetModule.outputs.subnetScope
// output pepSubnetScope object = pepSubnetModule.outputs.subnetScope
// output firewallSubnetScope object = firewallSubnetModule.outputs.subnetScope
// output maintSubnetScope object = maintSubnetModule.outputs.subnetScope
// output bastionSubnetScope object = bastionSubnetModule.outputs.subnetScope
// output proxySubnetScope object = proxySubnetModule.outputs.subnetScope
