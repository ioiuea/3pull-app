@description('デプロイ先リージョン')
param location string

@description('タグ情報')
param modulesTags object

@description('ロック')
param lockKind string

@description('NSG名')
param networkSecurityGroupName string

@description('セキュリティルール')
param securityRules array

@description('ログアナリティクス名')
param logAnalyticsName string

@description('リソースグループ名')
param logAnalyticsResourceGroupName string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: networkSecurityGroupName
  location: location
  tags: modulesTags
  properties: {
    securityRules: securityRules
  }
}

resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (lockKind != '') {
  name: 'del-lock-${networkSecurityGroupName}'
  scope: networkSecurityGroup
  properties: {
    level: lockKind
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostic-to-${logAnalyticsName}'
  scope: networkSecurityGroup
  properties: {
    workspaceId: resourceId(logAnalyticsResourceGroupName, 'Microsoft.OperationalInsights/workspaces', logAnalyticsName)
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: []
  }
}

output networkSecurityGroupScope object = networkSecurityGroup
output networkSecurityGroupName string = networkSecurityGroup.name
output networkSecurityGroupId string = networkSecurityGroup.id
output networkSecurityGroupLocation string = networkSecurityGroup.location
output networkSecurityGroupTags object = networkSecurityGroup.tags
