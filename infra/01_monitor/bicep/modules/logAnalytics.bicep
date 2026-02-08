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

@description('sku')
param logAnalyticsSku string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: logAnalyticsName
  location: location
  tags: modulesTags
  properties: {
    sku: {
      name: logAnalyticsSku
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
  }
}

resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (lockKind != '') {
  name: 'del-lock-${logAnalyticsName}'
  scope: logAnalytics
  properties: {
    level: lockKind
  }
}

output logAnalyticsScope object = logAnalytics
output logAnalyticsName string = logAnalytics.name
output logAnalyticsId string = logAnalytics.id
output logAnalyticsResourceGroupName string = resourceGroup().name
output logAnalyticsLocation string = logAnalytics.location
output logAnalyticsTags object = logAnalytics.tags
