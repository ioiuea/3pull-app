@description('デプロイ先リージョン')
param location string

@description('タグ情報')
param modulesTags object

@description('データ保持期間')
param retentionInDays int

@description('Ingestion用のパブリックネットワークアクセス')
param publicNetworkAccessForIngestion string

@description('クエリ用のパブリックネットワークアクセス')
param publicNetworkAccessForQuery string

@description('ロック')
param lockKind string

@description('ログアナリティクス名')
param logAnalyticsName string

@description('リソースグループ名')
param logAnalyticsResourceGroupName string

@description('アプリケーションインサイト名')
param applicationInsightsName string

@description('アプリケーションインサイトの種類')
param applicationInsightsType string

@description('ingestionモード')
param applicationInsightsIngestion string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: modulesTags
  kind: applicationInsightsType
  properties: {
    Application_Type: applicationInsightsType
    WorkspaceResourceId: resourceId(
      logAnalyticsResourceGroupName,
      'Microsoft.OperationalInsights/workspaces',
      logAnalyticsName
    )
    RetentionInDays: retentionInDays
    IngestionMode: applicationInsightsIngestion
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
  }
}

resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (lockKind != '') {
  name: 'del-lock-${applicationInsightsName}'
  scope: applicationInsights
  properties: {
    level: lockKind
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostic-to-${logAnalyticsName}'
  scope: applicationInsights
  properties: {
    workspaceId: resourceId(logAnalyticsResourceGroupName, 'Microsoft.OperationalInsights/workspaces', logAnalyticsName)
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
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

output applicationInsightsScope object = applicationInsights
output applicationInsightsName string = applicationInsights.name
output applicationInsightsId string = applicationInsights.id
output applicationInsightsResourceGroupName string = resourceGroup().name
output applicationInsightsLocation string = applicationInsights.location
output applicationInsightsTags object = applicationInsights.tags
