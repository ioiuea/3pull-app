// ###########################################
// 02_network (phase 2): Firewall
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
  billing: 'infra'
}

@description('VNETの名称')
param vnetName string = 'vnet-${environmentName}-${systemName}-app'

@description('Firewall IDS/IPS 有効化 (true: Premium, false: Standard)')
param enableFirewallIdps bool = loadJsonContent('../../../common.parameter.json').enableFirewallIdps

@description('ロック')
param lockKind string = 'CanNotDelete'

// ###########################################
// モジュールの定義
// ###########################################

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: 'rg-${environmentName}-${systemName}-${modulesName}'
}

resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  name: '${vnetName}/AzureFirewallSubnet'
  scope: resourceGroup
}

module publicIPModule './modules/publicIP.bicep' = {
  name: 'publicIP-${currentDateTime}'
  scope: resourceGroup
  params: {
    location: location
    modulesTags: modulesTags
    lockKind: lockKind
    publicIPName: 'pip-${environmentName}-${systemName}'
    publicIPSku: 'Standard'
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    protectionMode: 'Enabled'
  }
}

module firewallPolicyModule './modules/firewallPolicy.bicep' = {
  name: 'firewallPolicy-${currentDateTime}'
  scope: resourceGroup
  params: {
    location: location
    modulesTags: modulesTags
    lockKind: lockKind
    firewallPolicyName: 'afwp-${environmentName}-${systemName}'
    threatIntelMode: 'Alert'
    firewallPolicySku: enableFirewallIdps ? 'Premium' : 'Standard'
    intrusionDetectionMode: enableFirewallIdps ? 'Alert' : ''
  }
}

module firewallModule './modules/firewall.bicep' = {
  name: 'firewall-${currentDateTime}'
  scope: resourceGroup
  params: {
    location: location
    modulesTags: modulesTags
    lockKind: lockKind
    firewallName: 'afw-${environmentName}-${systemName}'
    firewallPolicyId: firewallPolicyModule.outputs.firewallPolicyId
    ipConfigurationName: 'ipconfig'
    subnetId: firewallSubnet.id
    publicIPId: publicIPModule.outputs.publicIPId
    sku: enableFirewallIdps ? 'Premium' : 'Standard'
    logAnalyticsName: logAnalyticsName
    logAnalyticsResourceGroupName: logAnalyticsResourceGroupName
  }
}

output firewallPrivateIp string = firewallModule.outputs.firewallPrivateIp
