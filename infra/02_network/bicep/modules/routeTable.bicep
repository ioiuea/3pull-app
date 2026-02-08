@description('デプロイ先リージョン')
param location string

@description('タグ情報')
param modulesTags object

@description('ルートテーブル名')
param routeTableName string

@description('ルート定義')
param routes array

resource routeTable 'Microsoft.Network/routeTables@2024-07-01' = {
  name: routeTableName
  location: location
  tags: modulesTags
  properties: {
    routes: routes
  }
}

output routeTableScope object = routeTable
output routeTableName string = routeTable.name
output routeTableId string = routeTable.id
