@description('デプロイ先リージョン')
param location string

@description('タグ情報')
param modulesTags object

@description('VNETの名称')
param virtualNetworkName string

@description('VNETのアドレスプレフィックス')
param addressPrefixes array

@description('VNETのDNSサーバー')
param dnsServers array

@description('DDoS Protection Plan のリソースID')
param ddosProtectionPlanId string

@description('ロック')
param lockKind string

@description('ログアナリティクス名')
param logAnalyticsName string

@description('リソースグループ名')
param logAnalyticsResourceGroupName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: virtualNetworkName
  location: location
  tags: modulesTags
  properties: union({
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
  }, empty(ddosProtectionPlanId) ? {} : {
    enableDdosProtection: true
    ddosProtectionPlan: {
      id: ddosProtectionPlanId
    }
  }, empty(dnsServers) ? {} : {
    dhcpOptions: {
      dnsServers: dnsServers
    }
  })
}

resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (lockKind != '') {
  name: 'del-lock-${virtualNetworkName}'
  scope: virtualNetwork
  properties: {
    level: lockKind
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostic-to-${logAnalyticsName}'
  scope: virtualNetwork
  properties: {
    workspaceId: resourceId(logAnalyticsResourceGroupName, 'Microsoft.OperationalInsights/workspaces', logAnalyticsName)
    logAnalyticsDestinationType: 'Dedicated'
    logs: []
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
        timeGrain: 'PT1M'
      }
    ]
  }
}

output virtualNetworkScope object = virtualNetwork
output virtualNetworkName string = virtualNetwork.name
output virtualNetworkId string = virtualNetwork.id
output virtualNetworkLocation string = virtualNetwork.location
output virtualNetworkTags object = virtualNetwork.tags
