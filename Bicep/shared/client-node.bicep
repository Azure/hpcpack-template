import { AzureMonitorLogSettings, diskTypes, DiskType } from 'types-and-vars.bicep'

/********************************
* Network settings
*/
param vnetRg string
param vnetName string
param subnetName string
param newPublicIp bool = true
param privateIp string?
param nsgName string?
param enableAcceleratedNetworking bool = false

/********************************
* VM settings
*/
param vmName string
param vmSize string
param enableManagedIdentity bool = false

//NOTE: The username is for both the local admin user and the domain user.
param username string

@secure()
param password string
param vmImage object
param vmOsDiskType DiskType
param vmDataDiskType DiskType
param vmDataDiskSize int
param vmDataDiskCount int

/********************************
* Domain settings
*/
param domainName string?
param domainOUPath string = ''

/********************************
* Azure Monitor Log settings
*/
param logSettings AzureMonitorLogSettings?

var publicIpSuffix = uniqueString(resourceGroup().id)
var nicSuffix = '-nic-${uniqueString(subnet.id)}'

var tags = empty(logSettings) ? {} : logSettings
var userMiResIdForLog = empty(logSettings) ? null : logSettings!.LA_MiResId

var systemIdentity = {
  type: 'SystemAssigned'
}
var userIdentity = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${userMiResIdForLog}': {}
  }
}
var systemAndUserIdentities = {
  type: 'SystemAssigned, UserAssigned'
  userAssignedIdentities: {
    '${userMiResIdForLog}': {}
  }
}
var identity = !enableManagedIdentity && empty(userMiResIdForLog)
  ? null
  : (enableManagedIdentity && !empty(userMiResIdForLog) ? systemAndUserIdentities : (enableManagedIdentity ? systemIdentity : userIdentity))


var hnDataDisks = [
  for j in range(0, ((vmDataDiskCount == 0) ? 1 : vmDataDiskCount)): {
    lun: j
    createOption: 'Empty'
    diskSizeGB: vmDataDiskSize
    managedDisk: {
      storageAccountType: diskTypes[vmDataDiskType]
    }
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  scope: resourceGroup(vnetRg)
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  parent: vnet
  name: subnetName
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' existing = if (!empty(nsgName)) {
  scope: resourceGroup(vnetRg)
  name: empty(nsgName) ? 'nsgName' : nsgName!
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (newPublicIp) {
  name: '${vmName}PublicIp'
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}${publicIpSuffix}')
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' =  {
  name: '${vmName}${nicSuffix}'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'IPConfig'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: empty(privateIp) ? 'Dynamic' : 'Static'
          privateIPAddress: privateIp
          publicIPAddress: !newPublicIp ? null : {
            id: publicIp.id
          }
        }
      }
    ]
    networkSecurityGroup: empty(nsgName) ? null : {
      id: nsg.id
    }
    enableAcceleratedNetworking: enableAcceleratedNetworking
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: resourceGroup().location
  identity: identity
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: username
      adminPassword: password
      windowsConfiguration: {
        enableAutomaticUpdates: false
      }
    }
    storageProfile: {
      imageReference: vmImage
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadOnly'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskTypes[vmOsDiskType]
        }
      }
      dataDisks: ((vmDataDiskCount == 0) ? [] : hnDataDisks)
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

resource joinDomain 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (!empty(domainName)) {
  parent: vm
  name: 'JoinADDomain'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      OUPath: domainOUPath
      User: '${domainName}\\${username}'
      NumberOfRetries: '50'
      RetryIntervalInMilliseconds: '10000'
      Restart: 'true'
      Options: '3'
    }
    protectedSettings: {
      Password: password
    }
  }
}

output fqdn string = newPublicIp ? publicIp.properties.dnsSettings.fqdn : ''
