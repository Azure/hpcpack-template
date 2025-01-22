import { HpcPackRelease, HeadNodeImage, getHeadNodeImageRef, LinuxComputeNodeImage, linuxComputeNodeImages, DiskType, diskTypes, DiskCount, DiskSizeInGB, YesOrNo, YesOrNoOrAuto, sharedResxBaseUrl, isRDMACapable } from 'shared/types-and-vars.bicep'

@description('The release of HPC Pack')
param hpcPackRelease HpcPackRelease = '2019 Update 3'

@description('The path of the setup package. If you built your own image, you need to bake unzipped setup files into your image and specify this path. See https://github.com/Azure/hpcpack-template/blob/master/SharedResources/Src/InstallPrimaryHeadNode/xHpcPack/DSCResources/MSFT_xHpcHeadNodeInstall/MSFT_xHpcHeadNodeInstall.psm1 for more details.')
param setupPkgPath string?

@description('The name of the HPC cluster, also used as the head node name. It must contain between 3 and 15 characters with lowercase letters and numbers, and must start with a letter.')
@minLength(3)
@maxLength(15)
param clusterName string

@description('The operating system of the head node.')
param headNodeOS HeadNodeImage = 'WindowsServer2019'

@description('Specify only when \'CustomImage\' selected for headNodeOS. The resource Id of the head node image, it can be a managed VM image in your own subscription (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/images/&lt;ImageName&gt;) or a shared VM image from Azure Shared Image Gallery (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/galleries/&lt;GalleryName&gt;/images/&lt;ImageName&gt;/versions/&lt;ImageVersion&gt;).')
param headNodeImageResourceId string = '/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/images/xxx'

@description('The disk type of head node VM. Note that Premium_SSD only supports some VM sizes, see <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>')
param headNodeOsDiskType DiskType = 'Premium_SSD'

@description('The VM size of the head node, all available VM sizes in Azure can be found at <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>. Note that some VM sizes in the list are only available in some particular locations. Please check the availability and the price of the VM sizes at https://azure.microsoft.com/pricing/details/virtual-machines/windows/ before deployment.')
param headNodeVMSize string = 'Standard_DS4_v2'

@description('The Linux VM image of the compute nodes')
param computeNodeImage LinuxComputeNodeImage = 'CentOS_7.9'

@description('Specify only when \'CustomImage\' selected for computeNodeImage. The resource Id of the compute node image, it can be a managed VM image in your own subscription (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/images/&lt;ImageName&gt;) or a shared VM image from Azure Shared Image Gallery (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/galleries/&lt;GalleryName&gt;/images/&lt;ImageName&gt;/versions/&lt;ImageVersion&gt;).')
param computeNodeImageResourceId string = '/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/images/xxx'

@description('The name prefix of the compute nodes. It must be no more than 12 characters, begin with a letter, and contain only letters, numbers and hyphens. For example, if \'IaaSCN\' is specified, the compute node names will be \'IaaSCN000\', \'IaaSCN001\', ...')
@minLength(1)
@maxLength(12)
param computeNodeNamePrefix string = 'IaaSLnxCN'

@description('The number of the compute nodes.')
@minValue(1)
@maxValue(500)
param computeNodeNumber int = 10

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

@description('Administrator user name for the virtual machines.')
param adminUsername string = 'hpcadmin'

@description('Administrator password for the virtual machines. Password must meet complexity requirements, see https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements')
@secure()
param adminPassword string

@description('Specify the SSH public key for the Linux nodes if you want to use SSH Key pair to authenticate. If not specified, you can use the adminPassword to authenticate.')
param sshPublicKey string = ''

@description('Specify whether to enable system-assigned managed identity on the head node, and use it to manage the Azure IaaS compute nodes.')
param enableManagedIdentityOnHeadNode YesOrNo = 'Yes'

@description('Indicates whether to create a public IP address for head node.')
param createPublicIPAddressForHeadNode YesOrNo = 'Yes'

@description('Specify whether to create the Azure VMs with accelerated networking or not. Note accelerated networking is supported only for some VM sizes and Linux distributions. If you specify it as \'Yes\', you must specify accelerated networking supported VM sizes and operating systems for all the VMs in the cluster. More information about accelerated networking please see https://docs.microsoft.com/en-us/azure/virtual-network/create-vm-accelerated-networking-powershell.')
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

@secure()
@description('The AuthenticationKey for Linux nodes. Head nodes must have ClusterAuthenticationKey set in their registry so that it is included in HN\'s request headers to Linux nodes.')
param authenticationKey string = ''

@description('Monitor the HPC Pack cluster in Azure Monitor.')
param enableAzureMonitor YesOrNo = 'Yes'

var _enableAzureMonitor = (enableAzureMonitor == 'Yes')
var _clusterName = trim(clusterName)
var _computeNodeNamePrefix = trim(computeNodeNamePrefix)
var storageAccountName = 'hpc${uniqueString(resourceGroup().id,_clusterName)}'
var storageAccountId = storageAccount.id
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/22'
var virtualNetworkName = '${_clusterName}vnet'
var vnetID = vnet.outputs.vNetId
var subnetRef = '${vnetID}/subnets/${subnet1Name}'
var availabilitySetName = '${_clusterName}-avset'
var nsgName = 'hpcnsg-${uniqueString(resourceGroup().id)}'
var cnRDMACapable = isRDMACapable(computeNodeVMSize)
var hnRDMACapable = isRDMACapable(headNodeVMSize)
var autoEnableInfiniBand = (autoInstallInfiniBandDriver == 'Yes')
var useVmssForCN = (useVmssForComputeNodes == 'Yes')
var createHNInAVSet = ((!useVmssForCN) && ((availabilitySetOption == 'AllNodes') || ((availabilitySetOption == 'Auto') && hnRDMACapable)))
var createCNInAVSet = ((!useVmssForCN) && (((availabilitySetOption == 'AllNodes') || (availabilitySetOption == 'ComputeNodes')) || ((availabilitySetOption == 'Auto') && cnRDMACapable)))
var vmPriority = ((useSpotInstanceForComputeNodes == 'Yes') ? 'Spot' : 'Regular')
var computeVmssName = take(replace(_computeNodeNamePrefix, '-', ''), 9)
var vmssSinglePlacementGroup = (computeNodeNumber <= 100)

var _computeNodeImages = union(linuxComputeNodeImages, {
  CustomImage: {
    id: trim(computeNodeImageResourceId)
  }
})
var headNodeImageRef = getHeadNodeImageRef(hpcPackRelease, headNodeOS, trim(headNodeImageResourceId))
var computeNodeImageRef = _computeNodeImages[computeNodeImage]
var rdmaDriverSupportedCNImage = ((contains(computeNodeImage, 'CentOS_7') || contains(computeNodeImage, 'RHEL_7')) && (!contains(
  computeNodeImage,
  '_HPC'
)))

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

module vnet 'shared/vnet.bicep' = {
  name: 'createVNet'
  scope: resourceGroup()
  params: {
    vNetName: virtualNetworkName
    addressPrefix: addressPrefix
    subnetName: subnet1Name
    subnetPrefix: subnet1Prefix
  }
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
    enableAcceleratedNetworking: enableAcceleratedNetworking == 'Yes'
    enableManagedIdentity: enableManagedIdentityOnHeadNode == 'Yes'
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
    privateIp: '10.0.0.4'
    subnetId: subnetRef
  }
  dependsOn: [
    monitor
    nsg
  ]
}

resource setupHeadNode 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  name: '${_clusterName}/installSingleHeadNode'
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
        SetupPkgPath: setupPkgPath
        ClusterName: _clusterName
        SSLThumbprint: certSettings.thumbprint
        CNSize: computeNodeVMSize
        SubscriptionId: subscription().subscriptionId
        VNet: virtualNetworkName
        Subnet: subnet1Name
        Location: resourceGroup().location
        ResourceGroup: resourceGroup().name
        VaultResourceGroup: certSettings.vaultResourceGroup
        CertificateUrl: certSettings.url
        CNNamePrefix: _computeNodeNamePrefix
        AutoGSUseManagedIdentity: (enableManagedIdentityOnHeadNode == 'Yes')
      }
    }
    protectedSettings: {
      configurationArguments: {
        SetupUserCredential: {
          UserName: adminUsername
          Password: adminPassword
        }
        AzureStorageConnString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId,'2019-04-01').keys[0].value}'
        LinuxAuthenticationKey: authenticationKey
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
      imageOsPlatform: 'linux'
      adminUsername: adminUsername
      adminPassword: adminPassword
      sshPublicKey: sshPublicKey
      availabilitySetName: (createCNInAVSet ? availabilitySetName : '')
      vmPriority: vmPriority
      installRDMADriver: (cnRDMACapable && autoEnableInfiniBand && rdmaDriverSupportedCNImage)
      enableAcceleratedNetworking: (enableAcceleratedNetworking == 'Yes')
      certSettings: certSettings
      headNodeList: _clusterName
      joinDomain: false
      domainName: ''
      logSettings: _enableAzureMonitor ? monitor.outputs.logSettings : null
      authenticationKey: authenticationKey
    }
    dependsOn: [
      monitor
      availabilitySet
      headNode
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
    imageOsPlatform: 'linux'
    adminUsername: adminUsername
    adminPassword: adminPassword
    sshPublicKey: sshPublicKey
    singlePlacementGroup: vmssSinglePlacementGroup
    vmPriority: vmPriority
    installRDMADriver: (cnRDMACapable && autoEnableInfiniBand && rdmaDriverSupportedCNImage)
    enableAcceleratedNetworking: (enableAcceleratedNetworking == 'Yes')
    certSettings: certSettings
    headNodeList: _clusterName
    joinDomain: false
    domainName: ''
    authenticationKey: authenticationKey
  }
  dependsOn: [
    headNode
  ]
}

output clusterDNSName string = (createPublicIPAddressForHeadNode == 'No') ? '' : headNode.outputs.fqdn
