@description('DDoS Protection Plan 名称')
param ddosProtectionPlanName string

@description('DDoS Protection Plan のリージョン')
param location string

@description('タグ情報')
param modulesTags object

@description('既存の DDoS Protection Plan リソース ID')
param existingDdosProtectionPlanId string

resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2024-07-01' = if (empty(existingDdosProtectionPlanId)) {
  name: ddosProtectionPlanName
  location: location
  tags: modulesTags
}

output ddosProtectionPlanId string = empty(existingDdosProtectionPlanId) ? ddosProtectionPlan.id : existingDdosProtectionPlanId
