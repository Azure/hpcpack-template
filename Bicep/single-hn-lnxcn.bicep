@description('The name of the HPC cluster, also used as the head node name. It must contain between 3 and 15 characters with lowercase letters and numbers, and must start with a letter.')
@minLength(3)
@maxLength(15)
param clusterName string

@description('The operating system of the head node.')
@allowed([
  'WindowsServer2022'
  'WindowsServer2019'
  'CustomImage'
])
param headNodeOS string = 'WindowsServer2019'

@description('Specify only when \'CustomImage\' selected for headNodeOS. The resource Id of the head node image, it can be a managed VM image in your own subscription (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/images/&lt;ImageName&gt;) or a shared VM image from Azure Shared Image Gallery (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/galleries/&lt;GalleryName&gt;/images/&lt;ImageName&gt;/versions/&lt;ImageVersion&gt;).')
param headNodeImageResourceId string = '/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/images/xxx'

@description('The disk type of head node VM. Note that Premium_SSD only supports some VM sizes, see <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>')
@allowed([
  'Standard_HDD'
  'Standard_SSD'
  'Premium_SSD'
])
param headNodeOsDiskType string = 'Premium_SSD'

@description('The VM size of the head node, all available VM sizes in Azure can be found at <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>. Note that some VM sizes in the list are only available in some particular locations. Please check the availability and the price of the VM sizes at https://azure.microsoft.com/pricing/details/virtual-machines/windows/ before deployment.')
param headNodeVMSize string = 'Standard_DS4_v2'

@description('The Linux VM image of the compute nodes')
@allowed([
  'CentOS_7.6'
  'CentOS_7.7'
  'CentOS_7.8'
  'CentOS_7.9'
  'CentOS_7.6_HPC'
  'CentOS_7.7_HPC'
  'CentOS_7.8_HPC'
  'CentOS_7.9_HPC'
  'CentOS_7.6_Gen2'
  'CentOS_7.7_Gen2'
  'CentOS_7.8_Gen2'
  'CentOS_7.9_Gen2'
  'CentOS_7.6_HPC_Gen2'
  'CentOS_7.7_HPC_Gen2'
  'CentOS_7.8_HPC_Gen2'
  'CentOS_7.9_HPC_Gen2'
  'AlmaLinux_8.5'
  'AlmaLinux_8.5_Gen2'
  'AlmaLinux_8.5_HPC'
  'AlmaLinux_8.5_HPC_Gen2'
  'AlmaLinux_8.6_HPC'
  'AlmaLinux_8.6_HPC_Gen2'
  'AlmaLinux_8.7_HPC'
  'AlmaLinux_8.7_HPC_Gen2'
  'Rocky Linux 8.6'
  'Rocky Linux 8.7'
  'RHEL_7.7'
  'RHEL_7.8'
  'RHEL_7.9'
  'RHEL_8.5'
  'RHEL_8.6'
  'RHEL_8.7'
  'RHEL_8.8'
  'RHEL_7.7_Gen2'
  'RHEL_7.8_Gen2'
  'RHEL_7.9_Gen2'
  'RHEL_8.5_Gen2'
  'RHEL_8.6_Gen2'
  'RHEL_8.7_Gen2'
  'RHEL_8.8_Gen2'
  'SLES_12_SP5'
  'SLES_12_SP5_HPC'
  'SLES_12_SP5_Gen2'
  'SLES_12_SP5_HPC_Gen2'
  'SLES_15_SP3_HPC'
  'Ubuntu_16.04'
  'Ubuntu_18.04'
  'Ubuntu_20.04'
  'Ubuntu_16.04_Gen2'
  'Ubuntu_18.04_Gen2'
  'Ubuntu_20.04_Gen2'
  'Ubuntu_18.04_HPC_Gen2'
  'Ubuntu_20.04_HPC_Gen2'
  'CustomImage'
])
param computeNodeImage string = 'CentOS_7.9'

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
@allowed([
  'Standard_HDD'
  'Standard_SSD'
  'Premium_SSD'
])
param computeNodeOsDiskType string = 'Standard_HDD'

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

@description('Name of the KeyVault in which the certificate is stored.')
param vaultName string

@description('Resource Group of the KeyVault in which the certificate is stored.')
param vaultResourceGroup string

@description('Url of the certificate with version in KeyVault e.g. https://testault.vault.azure.net/secrets/testcert/b621es1db241e56a72d037479xab1r7.')
param certificateUrl string

@description('Thumbprint of the certificate.')
param certThumbprint string

@description('Specify whether to enable system-assigned managed identity on the head node, and use it to manage the Azure IaaS compute nodes.')
@allowed([
  'Yes'
  'No'
])
param enableManagedIdentityOnHeadNode string = 'Yes'

@description('Indicates whether to create a public IP address for head node.')
@allowed([
  'Yes'
  'No'
])
param createPublicIPAddressForHeadNode string = 'Yes'

@description('Specify whether to create the Azure VMs with accelerated networking or not. Note accelerated networking is supported only for some VM sizes and Linux distributions. If you specify it as \'Yes\', you must specify accelerated networking supported VM sizes and operating systems for all the VMs in the cluster. More information about accelerated networking please see https://docs.microsoft.com/en-us/azure/virtual-network/create-vm-accelerated-networking-powershell.')
@allowed([
  'Yes'
  'No'
])
param enableAcceleratedNetworking string = 'No'

@description('The number of data disks attached to the head node VM.')
@allowed([
  0
  1
  2
  4
  8
])
param headNodeDataDiskCount int = 0

@description('The size in GB of each data disk that is attached to the head node VM.')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
])
param headNodeDataDiskSize int = 128

@description('Head node data disk type. Note that Premium_SSD only supports some VM sizes, see <a href=\'https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>')
@allowed([
  'Standard_HDD'
  'Standard_SSD'
  'Premium_SSD'
])
param headNodeDataDiskType string = 'Standard_HDD'

@description('The number of data disks attached to the compute node VM.')
@allowed([
  0
  1
  2
  4
  8
])
param computeNodeDataDiskCount int = 0

@description('The size in GB of each data disk that is attached to the compute node VM.')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
])
param computeNodeDataDiskSize int = 128

@description('Compute node data disk type. Note that Premium_SSD only supports some VM sizes, see <a href=\'https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes\' target=\'_blank\'>Azure VM Sizes</a>')
@allowed([
  'Standard_HDD'
  'Standard_SSD'
  'Premium_SSD'
])
param computeNodeDataDiskType string = 'Standard_HDD'

@description('Specify whether you want to use the experimental feature to create compute nodes as VM scale set. Note that it is not recommended to use this feature in production cluster.')
@allowed([
  'Yes'
  'No'
])
param useVmssForComputeNodes string = 'No'

@description('Specify whether you want to use the experimental feature to create compute nodes as <a href=\'https://azure.microsoft.com/pricing/spot/\' target=\'_blank\'>Azure Spot instances</a>. Note that it is not recommended to use this feature in production cluster.')
@allowed([
  'Yes'
  'No'
])
param useSpotInstanceForComputeNodes string = 'No'

@description('Specify whether you want to install InfiniBandDriver automatically for the VMs with InfiniBand network. This setting is ignored for the VMs without InfiniBand network.')
@allowed([
  'Yes'
  'No'
])
param autoInstallInfiniBandDriver string = 'Yes'

var _clusterName = trim(clusterName)
var _vaultName = trim(vaultName)
var _vaultResourceGroup = trim(vaultResourceGroup)
var _certThumbprint = trim(certThumbprint)
var _computeNodeNamePrefix = trim(computeNodeNamePrefix)
var managedIdentity = {
  type: 'SystemAssigned'
}
var emptyArray = []
var diskTypes = {
  Standard_HDD: 'Standard_LRS'
  Standard_SSD: 'StandardSSD_LRS'
  Premium_SSD: 'Premium_LRS'
}
var hnDataDisks = [
  for j in range(0, ((headNodeDataDiskCount == 0) ? 1 : headNodeDataDiskCount)): {
    lun: j
    createOption: 'Empty'
    diskSizeGB: headNodeDataDiskSize
    managedDisk: {
      storageAccountType: diskTypes[headNodeDataDiskType]
    }
  }
]

var storageAccountName = 'hpc${uniqueString(resourceGroup().id,_clusterName)}'
var storageAccountId = storageAccount.id
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/22'
var virtualNetworkName = '${_clusterName}vnet'
var vnetID = virtualNetwork.id
var subnetRef = '${vnetID}/subnets/${subnet1Name}'
var publicIPName = '${_clusterName}publicip'
var publicIPDNSNameLabel = '${toLower(_clusterName)}${uniqueString(resourceGroup().id)}'
var publicIPAddressType = 'Dynamic'
var publicIpAddressId = {
  id: publicIP.id
}
var availabilitySetName = '${_clusterName}-avset'
var _availabilitySet = {
  id: availabilitySet.id
}
var uniqueSuffix = uniqueString(subnetRef)
var uniqueNicSuffix = '-nic-${uniqueSuffix}'
var _nicNameHN = '${_clusterName}${uniqueNicSuffix}'
var nsgName = 'hpcnsg-${uniqueString(resourceGroup().id,subnetRef)}'
var networkSecurityGroupId = {
  id: nsg.id
}
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
var winCertSecrets = [
  {
    sourceVault: {
      id: resourceId(_vaultResourceGroup, 'Microsoft.KeyVault/vaults', _vaultName)
    }
    vaultCertificates: [
      {
        certificateUrl: certificateUrl
        certificateStore: 'My'
      }
    ]
  }
]
var lnxCertSecrets = [
  {
    sourceVault: {
      id: resourceId(_vaultResourceGroup, 'Microsoft.KeyVault/vaults', _vaultName)
    }
    vaultCertificates: [
      {
        certificateUrl: certificateUrl
      }
    ]
  }
]
var headNodeImages = {
  WindowsServer2019: {
    publisher: 'MicrosoftWindowsServerHPCPack'
    offer: 'WindowsServerHPCPack'
    sku: '2019hn-ws2019'
    version: 'latest'
  }
  WindowsServer2022: {
    publisher: 'MicrosoftWindowsServerHPCPack'
    offer: 'WindowsServerHPCPack'
    sku: '2019hn-ws2022'
    version: 'latest'
  }
  CustomImage: {
    id: trim(headNodeImageResourceId)
  }
}
var computeNodeImages = {
  'AlmaLinux_8.5': {
    publisher: 'almalinux'
    offer: 'almalinux'
    sku: '8_5'
    version: 'latest'
  }
  'AlmaLinux_8.5_Gen2': {
    publisher: 'almalinux'
    offer: 'almalinux'
    sku: '8_5-gen2'
    version: 'latest'
  }
  'AlmaLinux_8.5_HPC': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_5-hpc'
    version: 'latest'
  }
  'AlmaLinux_8.5_HPC_Gen2': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_5-hpc-gen2'
    version: 'latest'
  }
  'AlmaLinux_8.6_HPC': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_6-hpc'
    version: 'latest'
  }
  'AlmaLinux_8.6_HPC_Gen2': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_6-hpc-gen2'
    version: 'latest'
  }
  'AlmaLinux_8.7_HPC': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_7-hpc-gen1'
    version: 'latest'
  }
  'AlmaLinux_8.7_HPC_Gen2': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_7-hpc-gen2'
    version: 'latest'
  }
  'Rocky Linux 8.6': {
    publisher: 'erockyenterprisesoftwarefoundationinc1653071250513'
    offer: 'rockylinux'
    sku: 'free'
    version: '8.6.0'
  }
  'Rocky Linux 8.7': {
    publisher: 'erockyenterprisesoftwarefoundationinc1653071250513'
    offer: 'rockylinux'
    sku: 'free'
    version: '8.7.0'
  }
  'CentOS_7.6': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7.6'
    version: 'latest'
  }
  'CentOS_7.7': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7.7'
    version: 'latest'
  }
  'CentOS_7.8': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_8'
    version: 'latest'
  }
  'CentOS_7.9': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_9'
    version: 'latest'
  }
  'CentOS_7.6_HPC': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7.6'
    version: 'latest'
  }
  'CentOS_7.7_HPC': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7.7'
    version: 'latest'
  }
  'CentOS_7.8_HPC': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_8'
    version: 'latest'
  }
  'CentOS_7.9_HPC': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_9'
    version: 'latest'
  }
  'CentOS_7.6_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_6-gen2'
    version: 'latest'
  }
  'CentOS_7.7_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_7-gen2'
    version: 'latest'
  }
  'CentOS_7.8_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_8-gen2'
    version: 'latest'
  }
  'CentOS_7.9_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_9-gen2'
    version: 'latest'
  }
  'CentOS_7.6_HPC_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_6gen2'
    version: 'latest'
  }
  'CentOS_7.7_HPC_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_7-gen2'
    version: 'latest'
  }
  'CentOS_7.8_HPC_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_8-gen2'
    version: 'latest'
  }
  'CentOS_7.9_HPC_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_9-gen2'
    version: 'latest'
  }
  'RHEL_7.7': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '7.7'
    version: 'latest'
  }
  'RHEL_7.8': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '7.8'
    version: 'latest'
  }
  'RHEL_7.9': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '7_9'
    version: 'latest'
  }
  'RHEL_8.5': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '8_5'
    version: 'latest'
  }
  'RHEL_8.6': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '8_6'
    version: 'latest'
  }
  'RHEL_8.7': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '8_7'
    version: 'latest'
  }
  'RHEL_8.8': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '8_8'
    version: 'latest'
  }
  'RHEL_7.7_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '77-gen2'
    version: 'latest'
  }
  'RHEL_7.8_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '78-gen2'
    version: 'latest'
  }
  'RHEL_7.9_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '79-gen2'
    version: 'latest'
  }
  'RHEL_8.5_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '85-gen2'
    version: 'latest'
  }
  'RHEL_8.6_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '86-gen2'
    version: 'latest'
  }
  'RHEL_8.7_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '87-gen2'
    version: 'latest'
  }
  'RHEL_8.8_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '88-gen2'
    version: 'latest'
  }
  SLES_12_SP5: {
    publisher: 'SUSE'
    offer: 'sles-12-sp5'
    sku: 'gen1'
    version: 'latest'
  }
  SLES_12_SP5_HPC: {
    publisher: 'SUSE'
    offer: 'sles-12-sp5-hpc'
    sku: 'gen1'
    version: 'latest'
  }
  SLES_12_SP5_Gen2: {
    publisher: 'SUSE'
    offer: 'sles-12-sp5'
    sku: 'gen2'
    version: 'latest'
  }
  SLES_12_SP5_HPC_Gen2: {
    publisher: 'SUSE'
    offer: 'sles-12-sp5-hpc'
    sku: 'gen2'
    version: 'latest'
  }
  SLES_15_SP3_HPC: {
    publisher: 'SUSE'
    offer: 'sles-15-sp3-hpc'
    sku: 'gen1'
    version: 'latest'
  }
  'Ubuntu_16.04': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '16.04-LTS'
    version: 'latest'
  }
  'Ubuntu_18.04': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18.04-LTS'
    version: 'latest'
  }
  'Ubuntu_20.04': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts'
    version: 'latest'
  }
  'Ubuntu_16.04_Gen2': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '16_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu_18.04_Gen2': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu_20.04_Gen2': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu_18.04_HPC_Gen2': {
    publisher: 'Microsoft-DSVM'
    offer: 'Ubuntu-HPC'
    sku: '1804'
    version: 'latest'
  }
  'Ubuntu_20.04_HPC_Gen2': {
    publisher: 'Microsoft-DSVM'
    offer: 'Ubuntu-HPC'
    sku: '2004'
    version: 'latest'
  }
  CustomImage: {
    id: trim(computeNodeImageResourceId)
  }
}
var headNodeImageRef = headNodeImages[headNodeOS]
var computeNodeImageRef = computeNodeImages[computeNodeImage]
var rdmaDriverSupportedCNImage = ((contains(computeNodeImage, 'CentOS_7') || contains(computeNodeImage, 'RHEL_7')) && (!contains(
  computeNodeImage,
  '_HPC'
)))
var sharedResxBaseUrl = 'https://raw.githubusercontent.com/Azure/hpcpack-template/master/HPCPack2019/shared-resources'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: virtualNetworkName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (createPublicIPAddressForHeadNode == 'Yes') {
  name: publicIPName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: publicIPDNSNameLabel
    }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = if (createPublicIPAddressForHeadNode == 'Yes') {
  name: nsgName
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'allow-HTTPS'
        properties: {
          description: 'Allow Https'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-RDP'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-HPCSession'
        properties: {
          description: 'Allow HPC Session service'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9090'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1020
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-HPCBroker'
        properties: {
          description: 'Allow HPC Broker service'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9087'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1030
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-HPCBrokerWorker'
        properties: {
          description: 'Allow HPC Broker worker'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9091'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1040
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-HPCDataService'
        properties: {
          description: 'Allow HPC Data service'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9094 '
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1050
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource hnNIC 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: _nicNameHN
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'IPConfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.4'
          publicIPAddress: ((createPublicIPAddressForHeadNode == 'Yes') ? publicIpAddressId : null)
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: ((createPublicIPAddressForHeadNode == 'Yes') ? networkSecurityGroupId : null)
    enableAcceleratedNetworking: (enableAcceleratedNetworking == 'Yes')
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

resource headNode 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: _clusterName
  location: resourceGroup().location
  identity: ((enableManagedIdentityOnHeadNode == 'Yes') ? managedIdentity : null)
  properties: {
    availabilitySet: (createHNInAVSet ? _availabilitySet : null)
    hardwareProfile: {
      vmSize: headNodeVMSize
    }
    osProfile: {
      computerName: _clusterName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
      }
      secrets: winCertSecrets
    }
    storageProfile: {
      imageReference: headNodeImageRef
      osDisk: {
        name: '${_clusterName}-osdisk'
        caching: 'ReadOnly'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskTypes[headNodeOsDiskType]
        }
      }
      dataDisks: ((headNodeDataDiskCount == 0) ? emptyArray : hnDataDisks)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${_clusterName}${uniqueNicSuffix}')
        }
      ]
    }
  }
  dependsOn: [
    hnNIC
  ]
}

resource roleAssignmentOnRg 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableManagedIdentityOnHeadNode == 'Yes') {
  name: guid(resourceGroup().id, _clusterName)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: headNode.identity.principalId
  }
}

module roleAssigmentOnKeyVault 'shared/access-to-key-vault.bicep' = if (enableManagedIdentityOnHeadNode == 'Yes') {
  name: 'msiKeyVaultRoleAssignment'
  scope: resourceGroup(_vaultResourceGroup)
  params: {
    keyVaultName: _vaultName
    principalId: headNode.identity.principalId
  }
}

resource installInfiniBandDriver 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (hnRDMACapable && autoEnableInfiniBand) {
  parent: headNode
  name: 'installInfiniBandDriver'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'InfiniBandDriverWindows'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
  }
}

resource installSingleHeadNode 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: headNode
  name: 'installSingleHeadNode'
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
        SSLThumbprint: _certThumbprint
        CNSize: computeNodeVMSize
        SubscriptionId: subscription().subscriptionId
        VNet: virtualNetworkName
        Subnet: subnet1Name
        Location: resourceGroup().location
        ResourceGroup: resourceGroup().name
        VaultResourceGroup: _vaultResourceGroup
        CertificateUrl: certificateUrl
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
      }
    }
  }
  dependsOn: [
    installInfiniBandDriver
  ]
}

module computeNodes 'shared/compute-node.bicep' = [
  for i in range(0, computeNodeNumber): {
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
      secrets: lnxCertSecrets
      certThumbprint: _certThumbprint
      headNodeList: _clusterName
      joinDomain: false
      domainName: ''
    }
    dependsOn: [
      availabilitySet
      hnNIC
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
    secrets: lnxCertSecrets
    certThumbprint: _certThumbprint
    headNodeList: _clusterName
    joinDomain: false
    domainName: ''
  }
  dependsOn: [
    hnNIC
  ]
}

output clusterDNSName string = ((createPublicIPAddressForHeadNode == 'No')
  ? ''
  : reference(publicIpAddressId.id, '2019-04-01').dnsSettings.fqdn)
