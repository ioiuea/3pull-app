// ###########################################
// 03_service (phase 1): Maintenance VM
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
param modulesName string = 'svc'

@description('タグ情報')
param modulesTags object = {
  environmentName: environmentName
  systemName: systemName
  modulesName: modulesName
  createdBy: 'bicep'
  billing: 'infra'
}

@description('VNETのリソースグループ')
param nwResourceGroup string = 'rg-${environmentName}-${systemName}-nw'

@description('VNETの名称')
param vnetName string = 'vnet-${environmentName}-${systemName}'

@description('ロック')
param lockKind string = 'CanNotDelete'

// ###########################################
// maint VM パラメータ
// ###########################################

@description('maint 用 NIC 名')
param maintNicName string

@description('maint 用サブネット名')
param maintSubnetName string

@description('maint 用仮想マシン名')
param maintVmName string

@description('maint 用仮想マシンサイズ')
param maintVmSize string = 'Standard_D4as_v5'

@description('管理者ユーザー名')
param maintVmAdminUsername string = 'adminUser'

@description('管理者パスワード')
@secure()
param maintVmAdminPassword string

@description('OS イメージ情報')
param maintVmImageReference object = {
  publisher: 'canonical'
  offer: 'ubuntu-24_04-lts'
  sku: 'server'
  version: 'latest'
}

@description('OS ディスク情報')
param maintVmOsDisk object = {
  createOption: 'FromImage'
  diskSizeGB: 512
  managedDisk: {
    storageAccountType: 'PremiumSSD_LRS'
  }
  osType: 'Linux'
  deleteOption: 'Delete'
}

@description('ブート診断の有効化')
param maintBootDiagnosticsEnabled bool = true

@description('セキュリティタイプ')
param maintSecurityType string = 'TrustedLaunch'

@description('セキュアブートの有効化')
param maintSecureBootEnabled bool = true

@description('vTPMの有効化')
param maintVTpmEnabled bool = true

// ###########################################
// モジュールの定義
// ###########################################

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-${environmentName}-${systemName}-${modulesName}'
  location: location
  tags: modulesTags
}

module maintVirtualMachine './modules/virtualMachine.bicep' = {
  name: 'maintVirtualMachine-${currentDateTime}'
  scope: resourceGroup
  params: {
    location: location
    modulesTags: modulesTags
    lockKind: lockKind
    vmName: maintVmName
    vmSize: maintVmSize
    nicName: maintNicName
    nwResourceGroup: nwResourceGroup
    virtualNetworkName: vnetName
    subnetName: maintSubnetName
    adminUsername: maintVmAdminUsername
    adminPassword: maintVmAdminPassword
    imageReference: maintVmImageReference
    osDisk: maintVmOsDisk
    bootDiagnosticsEnabled: maintBootDiagnosticsEnabled
    securityType: maintSecurityType
    secureBootEnabled: maintSecureBootEnabled
    vTpmEnabled: maintVTpmEnabled
  }
}

output resourceGroupScope object = resourceGroup
output maintVmName string = maintVirtualMachine.outputs.vmName
output maintVmId string = maintVirtualMachine.outputs.vmId
output maintNicId string = maintVirtualMachine.outputs.nicId
output maintSubnetName string = maintSubnetName
