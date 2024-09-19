import { LinuxComputeNodeImage, linuxComputeNodeImages, DiskType, diskTypes, DiskCount, DiskSizeInGB, YesOrNo, YesOrNoOrAuto, sharedResxBaseUrl } from 'shared/types-and-vars.bicep'

@description('The name prefix of the compute nodes. It must be no more than 12 characters, begin with a letter, and contain only letters, numbers; The compute node name pattern is \'&lt;NamePrefix&gt;&lt;index&gt;\', the width of index is 3 characters, make sure the compute node names are unique in the domain forest.')
@minLength(1)
@maxLength(12)
param computeNodeNamePrefix string

@description('The start index of the compute node name series. For example, computeNodeNamePrefix is specified as \'IaaSCN\', and computeNodeNameStartIndex is specified as 2, the compute node names will be \'IaaSCN002\', \'IaaSCN003\', ...')
param computeNodeNameStartIndex int = 0

@description('The number of the compute nodes.')
@minValue(1)
@maxValue(50)
param computeNodeNumber int = 10

@description('The Linux VM image of the compute nodes')
param computeNodeImage LinuxComputeNodeImage = 'CentOS_7.9'

@description('Specify only when \'CustomImage\' selected for computeNodeImage. The resource Id of the compute node image, it can be a managed VM image in your own subscription (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/images/&lt;ImageName&gt;) or a shared VM image from Azure Shared Image Gallery (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/galleries/&lt;GalleryName&gt;/images/&lt;ImageName&gt;/versions/&lt;ImageVersion&gt;).')
param computeNodeImageResourceId string = '/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/images/xxx'

@description('The VM size of the compute nodes, all available VM sizes in Azure can be found at <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>. Note that some VM sizes in the list are only available in some particular locations. Please check the availability and the price of the VM sizes at https://azure.microsoft.com/pricing/details/virtual-machines/windows/ before deployment.')
param computeNodeVMSize string = 'Standard_D3_v2'

@description('The disk type of compute node VM. Note that Premium_SSD only supports some VM sizes, see <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>')
param computeNodeOsDiskType DiskType = 'Standard_HDD'

@description('The number of data disk(s) for each compute node.')
param dataDiskCount DiskCount = 0

@description('The size in GB of each data disk that is attached to the VM.')
param dataDiskSizeInGB DiskSizeInGB = 32

@description('The data disk type. Note that Premium_SSD only supports some VM sizes, see https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes.')
param dataDiskType DiskType = 'Standard_HDD'

@description('The administrator user name, for example \'johnlee\'.')
param adminUsername string

@description('Type of authentication to use on the Linux Virtual Machine.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the administrator.')
@secure()
param adminPasswordOrKey string

@description('The existing virtual network in which all VMs of the HPC cluster will be created.')
param virtualNetworkName string

@description('The resource group in which the existing virtual network was created.')
param virtualNetworkResourceGroupName string = resourceGroup().name

@description('The existing subnet in which all VMs of the HPC cluster will be created.')
param subnetName string

@description('The availability set name if you want to create the compute nodes in an availability set, it cannot be specified together with \'availabilityZones\'. For RDMA capable VMs, you shall specify this parameter. If you want to create the compute nodes in an existing availabity set, it must be in the same resource group which you selected for this deployment.')
param availabilitySetName string = ''

@description('The availability zones if you want to create the compute nodes in availability zones, it cannot be specified together with \'availabilitySetName\'. You can specify multiple zones separated with \',\', for example: \'1,2,3\'.')
param availabilityZones string = ''

@description('Specify whether to create the Azure VMs with accelerated networking or not. Note accelerated networking is supported only for some VM sizes and Linux distributions. More information about accelerated networking please see https://docs.microsoft.com/en-us/azure/virtual-network/create-vm-accelerated-networking-powershell.')
param enableAcceleratedNetworking YesOrNo = 'No'

@description('The cluster connection string is the list of head nodes separated by comma(\',\'). for example \'myhn\', \'myhn1,myhn2,myhn3\' if the head node(s) is not domain joined, or \'myhn.hpc.local\', \'myhn1.hpc.local,myhn2.hpc.local,myhn3.hpc.local\' if the head node(s) is domain joined. ')
param clusterConnectionString string

@description('Name of the KeyVault in which the certificate is stored.')
param vaultName string

@description('Resource Group of the KeyVault in which the certificate is stored.')
param vaultResourceGroup string

@description('Url of the certificate with version in KeyVault e.g. https://testault.vault.azure.net/secrets/testcert/b621es1db241e56a72d037479xab1r7.')
param certificateUrl string

@description('Thumbprint of the certificate.')
param certThumbprint string

@description('Specify whether you want to use the experimental feature to create compute nodes as VM scale set. Note that it is not recommended to use this feature in production cluster.')
param useVMScaleSet YesOrNo = 'No'

@description('Specify whether you want to use the experimental feature to create compute nodes as <a href=\'https://azure.microsoft.com/pricing/spot/\' target=\'_blank\'>Azure Spot instances</a>. Note that it is not recommended to use this feature in production cluster.')
param useSpotInstances YesOrNo = 'No'

@description('Specify whether you want to install InfiniBandDriver automatically for the VMs with InfiniBand network. This setting is ignored for the VMs without InfiniBand network.')
param autoInstallInfiniBandDriver YesOrNo = 'Yes'

@description('The DNS server for the compute nodes. If not specified, the DNS setting for the VNet will be applied. You can specify multiple DNS servers in order separated with \',\'.')
param dnsServer string = ''

@description('Optional, specify the resource ID of the user assigned identity to associate with the virtual machines in the form: /subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.ManagedIdentity/userAssignedIdentities/&lt;identityName&gt;')
param userAssignedIdentity string = ''

var _computeNodeNamePrefix = trim(computeNodeNamePrefix)
var emptyArray = []
var dnsServers = (empty(trim(dnsServer)) ? emptyArray : split(trim(dnsServer), ','))
var _computeNodeImages = union(linuxComputeNodeImages, {
  CustomImage: {
    id: trim(computeNodeImageResourceId)
  }
})
var computeNodeImageRef = _computeNodeImages[computeNodeImage]
var _availabilitySetName = (empty(trim(availabilitySetName)) ? 'passsyntaxchecking' : trim(availabilitySetName))
var availabilityZonesSS = (empty(trim(availabilityZones)) ? emptyArray : split(trim(availabilityZones), ','))
var availabilityZonesVM = (empty(trim(availabilityZones)) ? [''] : split(trim(availabilityZones), ','))
var vnetID = resourceId(trim(virtualNetworkResourceGroupName), 'Microsoft.Network/virtualNetworks', trim(virtualNetworkName))
var subnetRef = '${vnetID}/subnets/${trim(subnetName)}'
var rdmaASeries = [
  'Standard_A8'
  'Standard_A9'
]
var rdmaDriverSupportedCNImage = ((contains(computeNodeImage, 'CentOS_7') || contains(computeNodeImage, 'RHEL_7')) && (!contains(computeNodeImage, '_HPC')))
var cnRDMACapable = (contains(rdmaASeries, computeNodeVMSize) || contains(toLower(split(computeNodeVMSize, '_')[1]), 'r'))
var autoEnableInfiniBand = (autoInstallInfiniBandDriver == 'Yes')
var useVmssForCN = (useVMScaleSet == 'Yes')
var vmPriority = ((useSpotInstances == 'Yes') ? 'Spot' : 'Regular')
var computeVmssName = take(replace(_computeNodeNamePrefix, '-', ''), 9)
var vmssSinglePlacementGroup = ((length(availabilityZonesSS) <= 1) && (computeNodeNumber <= 100))

//Take the first name if multiple names are given.
var headNodeFullname = split(trim(clusterConnectionString), ',')[0]
//If headNodeFullname is "a.b.c", then take "a".
var headNodeName = split(headNodeFullname, '.')[0]

module monitor 'shared/azure-monitor-detector.bicep' = {
  name: 'monitor'
  params: {
    vmName: headNodeName
  }
}

resource availabilitySet 'Microsoft.Compute/availabilitySets@2019-03-01' = if (!(useVmssForCN || empty(trim(availabilitySetName)))) {
  name: _availabilitySetName
  location: resourceGroup().location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
}

module computeNodes 'shared/compute-node.bicep' = [
  for i in range(0, computeNodeNumber): if (!useVmssForCN) {
    name: 'create${_computeNodeNamePrefix}${padLeft(string((i+computeNodeNameStartIndex)),3,'0')}'
    params: {
      subnetId: subnetRef
      vmName: '${_computeNodeNamePrefix}${padLeft(string((i + computeNodeNameStartIndex)), 3, '0')}'
      vmSize: computeNodeVMSize
      osDiskType: diskTypes[computeNodeOsDiskType]
      dataDiskSizeInGB: dataDiskSizeInGB
      dataDiskCount: dataDiskCount
      dataDiskType: diskTypes[dataDiskType]
      imageReference: computeNodeImageRef
      imageOsPlatform: 'linux'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      sshPublicKey: ((authenticationType == 'sshPublicKey') ? adminPasswordOrKey : '')
      availabilitySetName: trim(availabilitySetName)
      availabilityZone: availabilityZonesVM[(i % length(availabilityZonesVM))]
      vmPriority: vmPriority
      installRDMADriver: (cnRDMACapable && autoEnableInfiniBand && rdmaDriverSupportedCNImage)
      enableAcceleratedNetworking: ((enableAcceleratedNetworking == 'Yes') ? bool('true') : bool('false'))
      dnsServers: dnsServers
      secrets: [
        {
          sourceVault: {
            id: resourceId(trim(vaultResourceGroup), 'Microsoft.KeyVault/vaults', trim(vaultName))
          }
          vaultCertificates: [
            {
              certificateUrl: trim(certificateUrl)
            }
          ]
        }
      ]
      certThumbprint: trim(certThumbprint)
      headNodeList: trim(clusterConnectionString)
      joinDomain: false
      domainName: ''
      userAssignedIdentity: trim(userAssignedIdentity)
      logSettings: monitor.outputs.logSettings
    }
    dependsOn: [
      availabilitySet
    ]
  }
]

module computeVmss 'shared/compute-vmss.bicep' = if ((computeNodeNumber > 0) && useVmssForCN) {
  name: 'create${computeVmssName}'
  params: {
    subnetId: subnetRef
    vmssName: computeVmssName
    vmSize: computeNodeVMSize
    vmNumber: computeNodeNumber
    osDiskType: diskTypes[computeNodeOsDiskType]
    dataDiskSizeInGB: dataDiskSizeInGB
    dataDiskCount: dataDiskCount
    dataDiskType: diskTypes[dataDiskType]
    imageReference: computeNodeImageRef
    imageOsPlatform: 'linux'
    adminUsername: adminUsername
    adminPassword: adminPasswordOrKey
    sshPublicKey: ((authenticationType == 'sshPublicKey') ? adminPasswordOrKey : '')
    singlePlacementGroup: vmssSinglePlacementGroup
    availabilityZones: availabilityZonesSS
    vmPriority: vmPriority
    installRDMADriver: (cnRDMACapable && autoEnableInfiniBand && rdmaDriverSupportedCNImage)
    enableAcceleratedNetworking: ((enableAcceleratedNetworking == 'Yes') ? bool('true') : bool('false'))
    dnsServers: dnsServers
    secrets: [
      {
        sourceVault: {
          id: resourceId(trim(vaultResourceGroup), 'Microsoft.KeyVault/vaults', trim(vaultName))
        }
        vaultCertificates: [
          {
            certificateUrl: trim(certificateUrl)
          }
        ]
      }
    ]
    certThumbprint: trim(certThumbprint)
    headNodeList: trim(clusterConnectionString)
    joinDomain: false
    domainName: ''
    userAssignedIdentity: trim(userAssignedIdentity)
  }
}
