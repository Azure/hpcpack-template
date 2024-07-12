@description('The Id of the subnet in which the node is created')
param subnetId string

@description('The VM name')
param vmName string

@description('The VM role size')
param vmSize string

@description('The OS disk type of the VM')
param osDiskType string = 'StandardSSD_LRS'

@description('The image reference')
param imageReference object

@description('The user name of the administrator')
param adminUsername string

@description('The password of the administrator')
@secure()
param adminPassword string

@description('The availability set name to join if specified')
param availabilitySetName string = ''

@description('The os disk size in GB')
@minValue(30)
@maxValue(1023)
param osDiskSizeInGB int = 128

@description('The size in GB of each data disk that is attached to the VM.')
param dataDiskSizeInGB int = 128

@description('The count of data disks attached to the VM.')
param dataDiskCount int = 0

@description('The data disk type of the VM')
param dataDiskType string = 'Standard_LRS'

@description('The custom data in base64 format')
param customData string = base64('None')

@description('Specify whether to install RDMA driver')
param installRDMADriver bool = false

@description('Specify whether the VM is enabled for automatic updates')
param enableAutomaticUpdates bool = false

@description('Specify whether to create the Azure VM with accelerated networking')
param enableAcceleratedNetworking bool = false

@description('The DNS servers')
param dnsServers array = []

@description('The property \'osProfile/secrets\', specify the set of certificates that shall be installed on the VM')
param secrets array = []

@description('The name of the Dsc extension')
param dscExtensionName string = 'configNodeWithDsc'

@description('The DSC public settings')
param dscSettings object

@description('The DSC protected settings')
@secure()
param dscProtectedSettings object = {}

var availabilitySet = {
  id: resourceId('Microsoft.Compute/availabilitySets', availabilitySetName)
}
var dnsSettings = {
  dnsServers: dnsServers
}
var nicName = '${vmName}-nic-${uniqueString(subnetId)}'
var emptyArray = []
var dataDiskNamePrefix = '${vmName}-datadisk-'
var dataDisks = [
  for j in range(0, ((dataDiskCount == 0) ? 1 : dataDiskCount)): {
    lun: j
    caching: 'None'
    name: (empty(dataDiskNamePrefix) ? null : '${dataDiskNamePrefix}${string(j)}')
    createOption: 'Empty'
    diskSizeGB: dataDiskSizeInGB
    managedDisk: {
      storageAccountType: dataDiskType
    }
  }
]

resource nic 'Microsoft.Network/networkInterfaces@2019-04-01' = {
  name: nicName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'IPConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    dnsSettings: (empty(dnsServers) ? null : dnsSettings)
    enableAcceleratedNetworking: enableAcceleratedNetworking
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vmName
  location: resourceGroup().location
  properties: {
    availabilitySet: (empty(availabilitySetName) ? null : availabilitySet)
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: customData
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
      }
      secrets: secrets
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadOnly'
        createOption: 'FromImage'
        diskSizeGB: osDiskSizeInGB
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      dataDisks: ((dataDiskCount == 0) ? emptyArray : dataDisks)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource rdmaDriver 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = if (installRDMADriver) {
  parent: vm
  name: 'installRDMADriver'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'InfiniBandDriverWindows'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
  }
}

resource dscExtension 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  parent: vm
  name: dscExtensionName
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.80'
    autoUpgradeMinorVersion: true
    settings: dscSettings
    protectedSettings: dscProtectedSettings
  }
  dependsOn: [
    rdmaDriver
  ]
}
