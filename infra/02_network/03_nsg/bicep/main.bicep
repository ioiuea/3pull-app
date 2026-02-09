// ###########################################
// 02_network (phase 3): NSG
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

@description('NSG定義')
param nsgs array = []

@description('ロック')
param lockKind string = 'CanNotDelete'

// ###########################################
// モジュールの定義
// ###########################################

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: 'rg-${environmentName}-${systemName}-${modulesName}'
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
