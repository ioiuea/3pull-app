@description('デプロイ先リージョン')
param location string

@description('タグ情報')
param modulesTags object

@description('ロック')
param lockKind string

@description('仮想マシン名')
param vmName string

@description('仮想マシンのサイズ')
param vmSize string

@description('仮想ネットワークのリソースグループ')
param nwResourceGroup string

@description('仮想ネットワーク名')
param virtualNetworkName string

@description('NIC名')
param nicName string

@description('サブネット名')
param subnetName string

@description('管理者ユーザー名')
param adminUsername string

@description('管理者パスワード')
@secure()
param adminPassword string

@description('イメージ情報')
param imageReference object

@description('OSディスクの設定')
param osDisk object

@description('ブート診断の有効化')
param bootDiagnosticsEnabled bool

@description('セキュアブートの有効化')
param secureBootEnabled bool

@description('セキュリティタイプ')
param securityType string

@description('vTPMの有効化')
param vTpmEnabled bool

resource nic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: resourceId(nwResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
  tags: modulesTags
}

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: osDisk
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: bootDiagnosticsEnabled
      }
    }
    securityProfile: {
      securityType: securityType
      uefiSettings: {
        secureBootEnabled: secureBootEnabled
        vTpmEnabled: vTpmEnabled
      }
    }
  }
  tags: modulesTags
}

resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (lockKind != '') {
  name: 'del-lock-${vmName}'
  scope: vm
  properties: {
    level: lockKind
  }
}

output vmId string = vm.id
output vmName string = vm.name
output nicId string = nic.id
