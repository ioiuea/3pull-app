// ###########################################
// 01_monitor : Log Analytics & Application Insights
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

// ###########################################
// モジュール共通パラメータ
// ###########################################

@description('モジュール群')
param modulesName string = 'monitor'

@description('タグ情報')
param modulesTags object = {
  environmentName: environmentName
  systemName: systemName
  modulesName: modulesName
  createdBy: 'bicep'
  billing: 'infra'
}

@description('データ保持期間')
param retentionInDays int = 365

@description('Ingestion用のパブリックネットワークアクセス')
param publicNetworkAccessForIngestion string = 'Disabled'

@description('クエリ用のパブリックネットワークアクセス')
param publicNetworkAccessForQuery string = 'Enabled'

@description('ロック')
param lockKind string = 'CanNotDelete'

// ###########################################
// Log Analytics パラメータ
// ###########################################

@description('sku')
param logAnalyticsSku string = 'perGB2018'

// ###########################################
// Application Insights パラメータ
// ###########################################

@description('Ingestionモード')
param applicationInsightsIngestion string = 'LogAnalytics'

@description('アプリケーションインサイトの種類')
param applicationInsightsType string = 'web'

// ###########################################
// モジュールの定義
// ###########################################

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-${environmentName}-${systemName}-${modulesName}'
  location: location
  tags: modulesTags
}

module logAnalyticsModule './modules/logAnalytics.bicep' = {
  name: 'log-${environmentName}-${systemName}-app-${currentDateTime}'
  scope: resourceGroup
  params: {
    location: location
    modulesTags: modulesTags
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
    lockKind: lockKind
    logAnalyticsName: 'log-${environmentName}-${systemName}-app'
    logAnalyticsSku: logAnalyticsSku
  }
}

module applicationInsightsModule './modules/applicationInsights.bicep' = {
  name: 'appi-${environmentName}-${systemName}-app-${currentDateTime}'
  scope: resourceGroup
  params: {
    location: location
    modulesTags: modulesTags
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
    lockKind: lockKind
    logAnalyticsName: logAnalyticsModule.outputs.logAnalyticsName
    logAnalyticsResourceGroupName: logAnalyticsModule.outputs.logAnalyticsResourceGroupName
    applicationInsightsName: 'appi-${environmentName}-${systemName}-app'
    applicationInsightsType: applicationInsightsType
    applicationInsightsIngestion: applicationInsightsIngestion
  }
}

output resourceGroupScope object = resourceGroup
output logAnalyticsScope object = logAnalyticsModule.outputs.logAnalyticsScope
output applicationInsightsScope object = applicationInsightsModule.outputs.applicationInsightsScope
