@description('デプロイ先リージョン')
param location string

@description('タグ情報')
param modulesTags object

@description('ロック')
param lockKind string

@description('ファイアウォールポリシー名')
param firewallPolicyName string

@description('侵入検知')
param threatIntelMode string

@description('sku')
param firewallPolicySku string

@description('侵入検知')
param intrusionDetectionMode string 

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-07-01' = {
  name: firewallPolicyName
  tags: modulesTags
  location: location
  properties: {
    threatIntelMode: threatIntelMode
    sku: {
      tier: firewallPolicySku
    }
    intrusionDetection: empty(intrusionDetectionMode)
      ? null
      : {
          mode: intrusionDetectionMode
        }
  }
}

resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (lockKind != '') {
  name: 'del-lock-${firewallPolicyName}'
  scope: firewallPolicy
  properties: {
    level: lockKind
  }
}

output firewallPolicyScope object = firewallPolicy
output firewallPolicyName string = firewallPolicy.name
output firewallPolicyId string = firewallPolicy.id
output firewallPolicyResourceGroupName string = resourceGroup().name
output firewallPolicyLocation string = firewallPolicy.location
output firewallPolicyTags object = firewallPolicy.tags
