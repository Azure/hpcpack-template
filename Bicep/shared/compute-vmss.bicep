import { OsType, CertificateSettings, certSecretForWindows, certSecretForLinux } from 'types-and-vars.bicep'

@description('The Id of the subnet in which the VMSS instances are created')
param subnetId string

@description('The VMSS name as well as the VM computer name prefix')
param vmssName string

@description('The number of VMs in the VMSS.')
param vmNumber int

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

@description('The availability zones where the VM instances are created if specified.')
param availabilityZones array = []

@description('The os disk size in GB')
@minValue(30)
@maxValue(1023)
param osDiskSizeInGB int = 128

@description('Specify whether the scale set is limited to a single placement group')
param singlePlacementGroup bool = true

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

@secure()
@description('The AuthenticationKey for Linux nodes. Head nodes must have ClusterAuthenticationKey set in their registry so that it is included in HN's request headers to Linux nodes.')
param authenticationKey string = ''

var userAssignedIdentityObject = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${userAssignedIdentity}': {}
  }
}
var isWindowsOS = (toLower(imageOsPlatform) == 'windows')
var trimmedSSHPublicKey = trim(sshPublicKey)
var windowsConfiguration = {
  enableAutomaticUpdates: enableAutomaticUpdates
}
var emptyArray = []
var dataDisks = [
  for j in range(0, ((dataDiskCount == 0) ? 1 : dataDiskCount)): {
    lun: j
    createOption: 'Empty'
    diskSizeGB: dataDiskSizeInGB
    managedDisk: {
      storageAccountType: dataDiskType
    }
  }
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
var lnxBasicExtension = [
  {
    name: 'installHPCNodeAgent'
    properties: {
      provisionAfterExtensions: (installRDMADriver ? array('installRDMADriver') : emptyArray)
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
  }
]
var winBasicExtension = [
  {
    name: 'configHpcComputeNode'
    properties: {
      provisionAfterExtensions: (installRDMADriver ? array('installRDMADriver') : emptyArray)
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
  }
]
var hpcWinDriverExtension = {
  name: 'installRDMADriver'
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'InfiniBandDriverWindows'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}
var hpcLinuxDriverExtension = {
  name: 'installRDMADriver'
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'InfiniBandDriverLinux'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}
var basicVmssExtension = (isWindowsOS ? winBasicExtension : lnxBasicExtension)
var hpcDriverExtension = (isWindowsOS ? hpcWinDriverExtension : hpcLinuxDriverExtension)
var vmssExtensions = (installRDMADriver ? concat(basicVmssExtension, array(hpcDriverExtension)) : basicVmssExtension)

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2019-03-01' = {
  name: vmssName
  location: resourceGroup().location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: vmNumber
  }
  identity: (empty(trim(userAssignedIdentity)) ? null : userAssignedIdentityObject)
  properties: {
    singlePlacementGroup: singlePlacementGroup
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: imageReference
        osDisk: {
          caching: 'ReadOnly'
          createOption: 'FromImage'
          diskSizeGB: osDiskSizeInGB
          managedDisk: {
            storageAccountType: osDiskType
          }
        }
        dataDisks: ((dataDiskCount == 0) ? emptyArray : dataDisks)
      }
      osProfile: {
        computerNamePrefix: vmssName
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
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nicconfig1'
            properties: {
              primary: true
              enableAcceleratedNetworking: enableAcceleratedNetworking
              dnsSettings: (empty(dnsServers) ? null : dnsSettings)
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    subnet: {
                      id: subnetId
                    }
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: vmssExtensions
      }
      priority: vmPriority
      evictionPolicy: ((vmPriority == 'Regular') ? null : 'Deallocate')
    }
  }
  zones: availabilityZones
}
