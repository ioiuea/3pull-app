targetScope = 'resourceGroup'

@description('環境名')
param environmentName string

@description('システム名称')
param systemName string

@description('デプロイ先リージョン')
param location string

@description('モジュール名')
param modulesName string = 'nw'

@description('Route Table 定義')
param routeTables array

var modulesTags = {
  environmentName: environmentName
  systemName: systemName
  modulesName: modulesName
  createdBy: 'bicep'
  billing: 'infra'
}

resource routeTableResources 'Microsoft.Network/routeTables@2024-07-01' = [
  for routeTable in routeTables: {
    name: 'rt-${environmentName}-${systemName}-${routeTable.name}'
    location: location
    tags: modulesTags
    properties: {
      routes: routeTable.routes
    }
  }
]

output routeTableNames array = [for routeTable in routeTables: 'rt-${environmentName}-${systemName}-${routeTable.name}']
