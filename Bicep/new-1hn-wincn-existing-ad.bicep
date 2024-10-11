import { HpcPackRelease, getHeadNodeImageRef, HeadNodeImage, WindowsComputeNodeImage, windowsComputeNodeImages, DiskType, diskTypes, DiskCount, DiskSizeInGB, YesOrNo, YesOrNoOrAuto, sharedResxBaseUrl } from 'shared/types-and-vars.bicep'

@description('The release of HPC Pack')
param hpcPackRelease HpcPackRelease = '2019 Update 3'

@description('The name of the HPC cluster. It must be unique in the domain forest; It must contain between 3 and 15 characters with lowercase letters and numbers, and must start with a letter.')
@minLength(3)
@maxLength(15)
param clusterName string

@description('The existing virtual network in which all VMs of the HPC cluster will be created.')
param virtualNetworkName string

@description('The resource group in which the existing virtual network was created.')
param virtualNetworkResourceGroupName string

@description('The existing subnet in which all VMs of the HPC cluster will be created.')
param subnetName string

@description('The fully qualified domain name (FQDN) for the existing domain forest in which the HPC cluster will join, for example \'hpc.cluster\'.')
param domainName string

@description('Optional, the organizational unit (OU) in the domain, for example \'OU=testOU,DC=domain,DC=Domain,DC=com\'. The default value is the default OU for machine objects in the domain.')
param domainOUPath string = ''

@description('The operating system of the head node.')
param headNodeOS HeadNodeImage = 'WindowsServer2019'

@description('Specify only when \'CustomImage\' selected for headNodeOS. The resource Id of the head node image, it can be a managed VM image in your own subscription (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/images/&lt;ImageName&gt;) or a shared VM image from Azure Shared Image Gallery (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/galleries/&lt;GalleryName&gt;/images/&lt;ImageName&gt;/versions/&lt;ImageVersion&gt;).')
param headNodeImageResourceId string = '/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/images/xxx'

@description('The disk type of head node VM. Note that Premium_SSD only supports some VM sizes, see <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>')
param headNodeOsDiskType DiskType = 'Premium_SSD'

@description('The VM size of the head node, all available VM sizes in Azure can be found at <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>. Note that some VM sizes in the list are only available in some particular locations. Please check the availability and the price of the VM sizes at https://azure.microsoft.com/pricing/details/virtual-machines/windows/ before deployment.')
param headNodeVMSize string = 'Standard_DS4_v2'

@description('The name prefix of the compute nodes. It must be no more than 12 characters, begin with a letter, and contain only letters, numbers and hyphens. For example, if \'IaaSCN\' is specified, the compute node names will be \'IaaSCN000\', \'IaaSCN001\', and so on. The compute node names must be unique in the domain forest.')
@minLength(1)
@maxLength(12)
param computeNodeNamePrefix string

@description('The number of the compute nodes.')
param computeNodeNumber int = 10

@description('The VM image of the compute nodes.')
param computeNodeImage WindowsComputeNodeImage = 'WindowsServer2019'

@description('Specify only when \'CustomImage\' selected for computeNodeImage. The resource Id of the compute node image, it can be a managed VM image in your own subscription (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/images/&lt;ImageName&gt;) or a shared VM image from Azure Shared Image Gallery (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/galleries/&lt;GalleryName&gt;/images/&lt;ImageName&gt;/versions/&lt;ImageVersion&gt;).')
param computeNodeImageResourceId string = '/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/images/xxx'

@description('The disk type of compute node VM. Note that Premium_SSD only supports some VM sizes, see <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>')
param computeNodeOsDiskType DiskType = 'Standard_HDD'

@description('The VM size of the compute nodes, all available VM sizes in Azure can be found at <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>. Note that some VM sizes in the list are only available in some particular locations. Please check the availability and the price of the VM sizes at https://azure.microsoft.com/pricing/details/virtual-machines/windows/ before deployment.')
param computeNodeVMSize string = 'Standard_D3_v2'

@description('Specify whether you want to create the HPC nodes in an Azure availability set. Select \'AllNodes\' to create both head node(s) and compute nodes in an availability set; select \'ComputeNodes\' to only create compute nodes in an availability set; select \'Auto\' to only create RDMA capable nodes in availability set; select \'None\' not to create an availability set.')
@allowed([
  'AllNodes'
  'ComputeNodes'
  'None'
  'Auto'
])
param availabilitySetOption string = 'Auto'

@description('Administrator user name for the virtual machines and the Active Directory domain.')
param adminUsername string = 'hpcadmin'

@description('Administrator password for the virtual machines and the Active Directory domain. Password must meet complexity requirements, see https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements')
@secure()
param adminPassword string

@description('Specify whether to enable system-assigned managed identity on the head node, and use it to manage the Azure IaaS compute nodes.')
param enableManagedIdentityOnHeadNode YesOrNo = 'Yes'

@description('Indicates whether to create a public IP address for head node.')
param createPublicIPAddressForHeadNode YesOrNo = 'Yes'

@description('Specify whether to create the Azure VMs with accelerated networking or not. Note accelerated networking is supported only for some VM sizes. If you specify it as \'Yes\', you must specify accelerated networking supported VM sizes for all the VMs in the cluster. More information about accelerated networking please see https://docs.microsoft.com/en-us/azure/virtual-network/create-vm-accelerated-networking-powershell.')
param enableAcceleratedNetworking YesOrNo = 'No'

@description('The number of data disks attached to the head node VM.')
param headNodeDataDiskCount DiskCount = 0

@description('The size in GB of each data disk that is attached to the head node VM.')
param headNodeDataDiskSize DiskSizeInGB = 128

@description('Head node data disk type. Note that Premium_SSD only supports some VM sizes, see <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>')
param headNodeDataDiskType DiskType = 'Standard_HDD'

@description('The number of data disks attached to the compute node VM.')
param computeNodeDataDiskCount DiskCount = 0

@description('The size in GB of each data disk that is attached to the compute node VM.')
param computeNodeDataDiskSize DiskSizeInGB = 128

@description('Compute node data disk type. Note that Premium_SSD only supports some VM sizes, see <a href=\'https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>')
param computeNodeDataDiskType DiskType = 'Standard_HDD'

@description('Specify whether you want to use the experimental feature to create compute nodes as VM scale set. Note that it is not recommended to use this feature in production cluster.')
param useVmssForComputeNodes YesOrNo = 'No'

@description('Specify whether you want to use the experimental feature to create compute nodes as <a href=\'https://azure.microsoft.com/pricing/spot/\' target=\'_blank\'>Azure Spot instances</a>. Note that it is not recommended to use this feature in production cluster.')
param useSpotInstanceForComputeNodes YesOrNo = 'No'

@description('Specify whether you want to install InfiniBandDriver automatically for the VMs with InfiniBand network. This setting is ignored for the VMs without InfiniBand network.')
param autoInstallInfiniBandDriver YesOrNo = 'Yes'

@description('Monitor the HPC Pack cluster in Azure Monitor.')
param enableAzureMonitor YesOrNo = 'Yes'

var _enableAzureMonitor = (enableAzureMonitor == 'Yes')
var _clusterName = trim(clusterName)
var _virtualNetworkName = trim(virtualNetworkName)
var _virtualNetworkResourceGroupName = trim(virtualNetworkResourceGroupName)
var _subnetName = trim(subnetName)
var _domainName = trim(domainName)
var _domainOUPath = trim(domainOUPath)
var _computeNodeNamePrefix = trim(computeNodeNamePrefix)

var storageAccountName = 'hpc${uniqueString(resourceGroup().id,_clusterName)}'
var storageAccountId = storageAccount.id
var vnetID = resourceId(
  _virtualNetworkResourceGroupName,
  'Microsoft.Network/virtualNetworks',
  _virtualNetworkName
)
var subnetRef = '${vnetID}/subnets/${_subnetName}'
var privateClusterFQDN = '${toLower(_clusterName)}.${_domainName}'
var availabilitySetName = '${_clusterName}-avset'
var nsgName = 'hpcnsg-${uniqueString(resourceGroup().id,subnetRef)}'
var rdmaASeries = [
  'Standard_A8'
  'Standard_A9'
]
var cnRDMACapable = (contains(rdmaASeries, computeNodeVMSize) || contains(
  toLower(split(computeNodeVMSize, '_')[1]),
  'r'
))
var hnRDMACapable = (contains(rdmaASeries, headNodeVMSize) || contains(toLower(split(headNodeVMSize, '_')[1]), 'r'))
var autoEnableInfiniBand = (autoInstallInfiniBandDriver == 'Yes')
var useVmssForCN = (useVmssForComputeNodes == 'Yes')
var createHNInAVSet = ((!useVmssForCN) && ((availabilitySetOption == 'AllNodes') || ((availabilitySetOption == 'Auto') && hnRDMACapable)))
var createCNInAVSet = ((!useVmssForCN) && (((availabilitySetOption == 'AllNodes') || (availabilitySetOption == 'ComputeNodes')) || ((availabilitySetOption == 'Auto') && cnRDMACapable)))
var vmPriority = ((useSpotInstanceForComputeNodes == 'Yes') ? 'Spot' : 'Regular')
var computeVmssName = take(replace(_computeNodeNamePrefix, '-', ''), 9)
var vmssSinglePlacementGroup = (computeNodeNumber <= 100)

var headNodeImageRef = getHeadNodeImageRef(hpcPackRelease, headNodeOS, trim(headNodeImageResourceId))
var _computeNodeImages = union(windowsComputeNodeImages, {
  CustomImage: {
    id: trim(computeNodeImageResourceId)
  }
})
var computeNodeImageRef = _computeNodeImages[computeNodeImage]

var certSettings = keyVault.outputs.certSettings

module keyVault 'shared/key-vault-with-cert.bicep' = {
  name: 'KeyVaultWithCert'
}

module monitor 'shared/azure-monitor.bicep' = if (_enableAzureMonitor) {
  name: 'AzureMonitor'
  params: {
    name: _clusterName
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

module nsg 'shared/nsg.bicep' = if (createPublicIPAddressForHeadNode == 'Yes') {
  name: 'nsg'
  params: {
    name: nsgName
  }
}

resource availabilitySet 'Microsoft.Compute/availabilitySets@2023-03-01' = if (createHNInAVSet || createCNInAVSet) {
  name: availabilitySetName
  location: resourceGroup().location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
}

module headNode 'shared/head-node.bicep' = {
  name: _clusterName
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    certSettings: certSettings
    clusterName: _clusterName
    createPublicIp: createPublicIPAddressForHeadNode == 'Yes'
    domainName: _domainName
    domainOUPath: _domainOUPath
    enableAcceleratedNetworking: enableAcceleratedNetworking == 'Yes'
    enableManagedIdentity: enableManagedIdentityOnHeadNode == 'Yes'
    externalVNetName: _virtualNetworkName
    externalVNetRg: _virtualNetworkResourceGroupName
    hnAvSetName: createHNInAVSet ? availabilitySet.name : null
    hnDataDiskCount: headNodeDataDiskCount
    hnDataDiskSize: headNodeDataDiskSize
    hnDataDiskType: headNodeDataDiskType
    hnImageRef: headNodeImageRef
    hnName: _clusterName
    hnOsDiskType: headNodeOsDiskType
    hnVMSize: headNodeVMSize
    installIBDriver:hnRDMACapable && autoEnableInfiniBand
    logSettings: _enableAzureMonitor ? monitor.outputs.logSettings : null
    amaSettings: _enableAzureMonitor ? monitor.outputs.amaSettings : null
    nsgName: createPublicIPAddressForHeadNode == 'Yes' ? nsgName : null
    subnetId: subnetRef
  }
  dependsOn: [
    monitor
    nsg
  ]
}

//TODO: Move this into a module
resource setupHeadNode 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  name: '${_clusterName}/setupHpcHeadNode'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.80'
    autoUpgradeMinorVersion: true
    settings: {
      configuration: {
        url: '${sharedResxBaseUrl}/InstallPrimaryHeadNode.ps1.zip'
        script: 'InstallPrimaryHeadNode.ps1'
        function: 'InstallPrimaryHeadNode'
      }
      configurationArguments: {
        ClusterName: _clusterName
        SSLThumbprint: certSettings.thumbprint
        CNSize: computeNodeVMSize
        SubscriptionId: subscription().subscriptionId
        VNet: _virtualNetworkName
        Subnet: _subnetName
        Location: resourceGroup().location
        ResourceGroup: _virtualNetworkResourceGroupName
        VaultResourceGroup: certSettings.vaultResourceGroup
        CertificateUrl: certSettings.url
        CNNamePrefix: _computeNodeNamePrefix
        AutoGSUseManagedIdentity: (enableManagedIdentityOnHeadNode == 'Yes')
      }
    }
    protectedSettings: {
      configurationArguments: {
        SetupUserCredential: {
          UserName: '${_domainName}\\${adminUsername}'
          Password: adminPassword
        }
        AzureStorageConnString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId,'2019-04-01').keys[0].value}'
      }
    }
  }
  dependsOn: [
    headNode
  ]
}

module computeNodes 'shared/compute-node.bicep' = [
  for i in range(0, computeNodeNumber): if (!useVmssForCN) {
    name: 'create${_computeNodeNamePrefix}${padLeft(string(i),3,'0')}'
    params: {
      subnetId: subnetRef
      vmName: '${_computeNodeNamePrefix}${padLeft(string(i), 3, '0')}'
      vmSize: computeNodeVMSize
      osDiskType: diskTypes[computeNodeOsDiskType]
      dataDiskSizeInGB: computeNodeDataDiskSize
      dataDiskCount: computeNodeDataDiskCount
      dataDiskType: diskTypes[computeNodeDataDiskType]
      imageReference: computeNodeImageRef
      imageOsPlatform: 'windows'
      adminUsername: adminUsername
      adminPassword: adminPassword
      availabilitySetName: (createCNInAVSet ? availabilitySetName : '')
      vmPriority: vmPriority
      installRDMADriver: (cnRDMACapable && autoEnableInfiniBand)
      enableAcceleratedNetworking: (enableAcceleratedNetworking == 'Yes')
      certSettings: certSettings
      headNodeList: _clusterName
      joinDomain: true
      domainName: _domainName
      domainOUPath: _domainOUPath
      logSettings: _enableAzureMonitor ? monitor.outputs.logSettings : null
    }
    dependsOn: [
      monitor
      availabilitySet
    ]
  }
]

module computeVmss 'shared/compute-vmss.bicep' = if ((computeNodeNumber > 0) && useVmssForCN) {
  name: 'create${computeVmssName}'
  params: {
    subnetId: subnetRef
    vmssName: computeVmssName
    vmNumber: computeNodeNumber
    vmSize: computeNodeVMSize
    osDiskType: diskTypes[computeNodeOsDiskType]
    dataDiskSizeInGB: computeNodeDataDiskSize
    dataDiskCount: computeNodeDataDiskCount
    dataDiskType: diskTypes[computeNodeDataDiskType]
    imageReference: computeNodeImageRef
    imageOsPlatform: 'windows'
    adminUsername: adminUsername
    adminPassword: adminPassword
    singlePlacementGroup: vmssSinglePlacementGroup
    vmPriority: vmPriority
    installRDMADriver: (cnRDMACapable && autoEnableInfiniBand)
    enableAcceleratedNetworking: (enableAcceleratedNetworking == 'Yes')
    certSettings: certSettings
    headNodeList: _clusterName
    joinDomain: true
    domainName: _domainName
    domainOUPath: _domainOUPath
  }
}

output clusterDNSName string = (createPublicIPAddressForHeadNode == 'No') ? privateClusterFQDN : headNode.outputs.fqdn
