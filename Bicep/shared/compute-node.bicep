import { OsType, AzureMonitorLogSettings, CertificateSettings, certSecretForWindows, certSecretForLinux } from 'types-and-vars.bicep'

@description('The Id of the subnet in which the node is created')
param subnetId string

@description('The VM name')
param vmName string

@description('The VM role size')
param vmSize string

@description('The OS disk type of the VM')
param osDiskType string = 'StandardSSD_LRS'

@description('The size in GB of each data disk that is attached to the VM.')
param dataDiskSizeInGB int = 128

@description('The count of data disks attached to the VM.')
param dataDiskCount int = 0

@description('The data disk type of the VM')
param dataDiskType string = 'Standard_LRS'

@description('The image reference')
param imageReference object

@description('The VM image OS platform for the compute nodes')
param imageOsPlatform OsType

@description('The user name of the administrator')
param adminUsername string

@description('The password of the administrator')
@secure()
param adminPassword string

@description('If specified, the SSH Key for the administrator, only valid for Linux Virtual Machine.')
param sshPublicKey string = ''

@description('The availability set name to join if specified, it cannot be specified together with \'availabilityZone\'.')
param availabilitySetName string = ''

@description('The availability zone where the VM is created if specified, it cannot be specified together with \'availabilitySetName\'.')
param availabilityZone string = ''

@description('The os disk size in GB')
@minValue(30)
@maxValue(1023)
param osDiskSizeInGB int = 128

@description('Specify the priority of the virtual machines in the scale set, Regular or Low.')
param vmPriority string = 'Regular'

@description('Specify whether to install RDMA driver')
param installRDMADriver bool = false

@description('Specify whether the VM is enabled for automatic updates, not used for Linux node')
param enableAutomaticUpdates bool = false

@description('Specify whether to create the Azure VM with accelerated networking')
param enableAcceleratedNetworking bool = false

@description('The certificate that shall be installed on the VM')
param certSettings CertificateSettings

@description('The head node list')
param headNodeList string

@description('Specify whether this node need to join domain.')
param joinDomain bool = false

@description('The fully qualified domain name (FQDN) for the domain forest in which the cluster is created.')
param domainName string = ''

@description('The organizational unit (OU) in the domain, used only when \'domainName\' is specified.')
param domainOUPath string = ''

@description('Optional, specify the resource ID of the user assigned identity to associate with the virtual machine in the form: /subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.ManagedIdentity/userAssignedIdentities/&lt;identityName&gt;')
param userAssignedIdentity string = ''

@description('The DNS servers in order, if not configured, the DNS servers configured in the virtual network will be used.')
param dnsServers array = []

@description('Specifies the license type for the virtual machines. Use \'Windows_Server\' for Azure Hybrid Benefit.')
param licenseType string = ''

@description('Azure Monitor log settings')
param logSettings AzureMonitorLogSettings?

@secure()
@description('The AuthenticationKey for Linux nodes. Head nodes must have ClusterAuthenticationKey set in their registry so that it is included in HN\'s request headers to Linux nodes.')
param authenticationKey string = ''

var tags = empty(logSettings) ? {} : logSettings
var userMiResIdForLog = empty(logSettings) ? '' : logSettings!.LA_MiResId

var _userAssignedIdentity = trim(userAssignedIdentity)
var _userMiResIdForLog = trim(userMiResIdForLog)

var noIdentity = empty(_userAssignedIdentity) && empty(_userMiResIdForLog)

var userIdentity = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${_userAssignedIdentity}': {}
  }
}
var userIdentityForLog = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${_userMiResIdForLog}': {}
  }
}

//NOTE: an variable of object value like { '': {}, '': {}, ... } cannot pass validation.
//So we need to avoid that here.
var bothIdentities = noIdentity
  ? null
  : {
      type: 'UserAssigned'
      userAssignedIdentities: {
        '${_userAssignedIdentity}': {}
        '${_userMiResIdForLog}': {}
      }
    }

var identity = noIdentity
  ? null
  : (!empty(_userAssignedIdentity) && !empty(_userMiResIdForLog) ? bothIdentities : (!empty(_userAssignedIdentity) ? userIdentity : userIdentityForLog))

var nicName = '${vmName}-nic-${uniqueString(subnetId)}'
var isWindowsOS = (toLower(imageOsPlatform) == 'windows')
var trimmedSSHPublicKey = trim(sshPublicKey)
var windowsConfiguration = {
  enableAutomaticUpdates: enableAutomaticUpdates
}
var emptyArray = []
var dataDisks = [
  for j in range(0, ((dataDiskCount == 0) ? 1 : dataDiskCount)): {
    lun: j
    name: '${vmName}-datadisk-${j}'
    createOption: 'Empty'
    diskSizeGB: dataDiskSizeInGB
    managedDisk: {
      storageAccountType: dataDiskType
    }
  }
]

var availabilitySet = {
  id: resourceId('Microsoft.Compute/availabilitySets', trim(availabilitySetName))
}
var availabilityZones = [
  trim(availabilityZone)
]
var dnsSettings = {
  dnsServers: dnsServers
}
var protectedSettings = {
  userPassword: adminPassword
}
var sshKeyConfig = {
  publicKeys: [
    {
      path: '/home/${adminUsername}/.ssh/authorized_keys'
      keyData: trimmedSSHPublicKey
    }
  ]
}
var linuxConfiguration = {
  disablePasswordAuthentication: (!empty(trimmedSSHPublicKey))
  ssh: (empty(trimmedSSHPublicKey) ? null : sshKeyConfig)
}

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
  identity: identity
  tags: tags
  properties: {
    availabilitySet: (empty(trim(availabilitySetName)) ? null : availabilitySet)
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: (isWindowsOS ? null : linuxConfiguration)
      windowsConfiguration: (isWindowsOS ? windowsConfiguration : null)
      secrets: [
        imageOsPlatform == 'windows'
          ? certSecretForWindows(certSettings.vaultResourceGroup, certSettings.vaultName, certSettings.url)
          : certSecretForLinux(certSettings.vaultResourceGroup, certSettings.vaultName, certSettings.url)
      ]
    }
    licenseType: ((licenseType == '') ? null : licenseType)
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
    priority: vmPriority
    evictionPolicy: ((vmPriority == 'Regular') ? null : 'Deallocate')
  }
  zones: (empty(trim(availabilityZone)) ? emptyArray : availabilityZones)
}

resource windowsIBDriver 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = if (isWindowsOS && installRDMADriver) {
  parent: vm
  name: 'installInfiniBandDriverWindows'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'InfiniBandDriverWindows'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: true
  }
}

resource windowsNodeAgent 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = if (isWindowsOS) {
  parent: vm
  name: 'configHpcComputeNode'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.HpcPack'
    type: 'HPCComputeNode'
    typeHandlerVersion: '16.2'
    autoUpgradeMinorVersion: true
    settings: {
      domainName: domainName
      ouPath: domainOUPath
      userName: adminUsername
      headNodeList: headNodeList
      certThumbprint: certSettings.thumbprint
      nonDomainRole: (!joinDomain)
    }
    protectedSettings: (joinDomain ? protectedSettings : null)
  }
  dependsOn: [
    windowsIBDriver
  ]
}

resource linuxIBDriver 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = if ((!isWindowsOS) && installRDMADriver) {
  parent: vm
  name: 'installInfiniBandDriverLinux'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'InfiniBandDriverLinux'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
  }
}

resource linuxNodeAgent 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = if (!isWindowsOS) {
  parent: vm
  name: 'installHPCNodeAgent'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.HpcPack'
    type: 'LinuxNodeAgent2016U1'
    typeHandlerVersion: '16.3'
    autoUpgradeMinorVersion: true
    settings: {
      ClusterConnectionString: headNodeList
      SSLThumbprint: certSettings.thumbprint
      DomainName: domainName
    }
    protectedSettings: {
      AuthenticationKey: authenticationKey
    }
  }
  dependsOn: [
    linuxIBDriver
  ]
}
