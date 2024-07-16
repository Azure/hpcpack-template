@description('The name of the HPC cluster, also used as the head node name and the host name prefix of the domain controller. It must contain between 3 and 12 characters with lowercase letters and numbers, and must start with a letter.')
@minLength(3)
@maxLength(12)
param clusterName string

@description('The fully qualified domain name (FQDN) for the private domain forest which will be created by this template, for example \'hpc.cluster\'.')
param domainName string = 'hpc.cluster'

//NOTE: Change the default size Standard_D2_v3 may cause VM extension "promoteDC" failure. The reason is unknown.
@description('The VM size for the domain controller, all available VM sizes in Azure can be found at https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes')
param domainControllerVMSize string = 'Standard_D2_v3'

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

@description('The name prefix of the compute nodes. It must be no more than 12 characters, begin with a letter, and contain only letters, numbers and hyphens. For example, if \'IaaSCN\' is specified, the compute node names will be \'IaaSCN000\', \'IaaSCN001\', ...')
@minLength(1)
@maxLength(12)
param computeNodeNamePrefix string = 'IaaSCN'

@description('The number of the compute nodes.')
param computeNodeNumber int = 10

@description('The VM image of the compute nodes.')
@allowed([
  'WindowsServer2012'
  'WindowsServer2012R2'
  'WindowsServer2016'
  'WindowsServer2019'
  'WindowsServer2022'
  'WindowsServer2012R2WithExcel'
  'WindowsServer2016WithExcel'
  'WindowsServer2012_Gen2'
  'WindowsServer2012R2_Gen2'
  'WindowsServer2016_Gen2'
  'WindowsServer2019_Gen2'
  'WindowsServer2022_Gen2'
  'CustomImage'
])
param computeNodeImage string = 'WindowsServer2019'

@description('Specify only when \'CustomImage\' selected for computeNodeImage. The resource Id of the compute node image, it can be a managed VM image in your own subscription (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/images/&lt;ImageName&gt;) or a shared VM image from Azure Shared Image Gallery (/subscriptions/&lt;SubscriptionId&gt;/resourceGroups/&lt;ResourceGroupName&gt;/providers/Microsoft.Compute/galleries/&lt;GalleryName&gt;/images/&lt;ImageName&gt;/versions/&lt;ImageVersion&gt;).')
param computeNodeImageResourceId string = '/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/images/xxx'

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

@description('Administrator user name for the virtual machines and the Active Directory domain.')
param adminUsername string = 'hpcadmin'

@description('Administrator password for the virtual machines and the Active Directory domain. Password must meet complexity requirements, see https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements')
@secure()
param adminPassword string

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

@description('Specify whether to create the Azure VMs with accelerated networking or not. Note accelerated networking is supported only for some VM sizes. If you specify it as \'Yes\', you must specify accelerated networking supported VM sizes for all the VMs in the cluster. More information about accelerated networking please see https://docs.microsoft.com/en-us/azure/virtual-network/create-vm-accelerated-networking-powershell.')
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

var dcSize = trim(domainControllerVMSize)
var _clusterName = trim(clusterName)
var _domainName = trim(domainName)
var _vaultName = trim(vaultName)
var _vaultResourceGroup = trim(vaultResourceGroup)
var _certThumbprint = trim(certThumbprint)
var _computeNodeNamePrefix = trim(computeNodeNamePrefix)
var diskTypes = {
  Standard_HDD: 'Standard_LRS'
  Standard_SSD: 'StandardSSD_LRS'
  Premium_SSD: 'Premium_LRS'
}

var storageAccountName = 'hpc${uniqueString(resourceGroup().id,_clusterName)}'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/22'
var virtualNetworkName = '${_clusterName}vnet'
var vnetID = vnet.id
var subnetRef = '${vnetID}/subnets/${subnet1Name}'
var privateClusterFQDN = '${toLower(_clusterName)}.${_domainName}'
var publicIPSuffix = uniqueString(resourceGroup().id)
var availabilitySetName = '${_clusterName}-avset'
var uniqueSuffix = uniqueString(subnetRef)
var uniqueNicSuffix = '-nic-${uniqueSuffix}'
var dcVMName = '${_clusterName}dc'
var dcNICName = '${dcVMName}${uniqueNicSuffix}'
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
var certSecrets = [
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
  WindowsServer2008R2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2008-R2-SP1'
    version: 'latest'
  }
  WindowsServer2012: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-Datacenter'
    version: 'latest'
  }
  WindowsServer2012R2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-R2-Datacenter'
    version: 'latest'
  }
  WindowsServer2016: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2016-Datacenter'
    version: 'latest'
  }
  WindowsServer2019: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-Datacenter'
    version: 'latest'
  }
  WindowsServer2022: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter'
    version: 'latest'
  }
  WindowsServer2012R2WithExcel: {
    publisher: 'MicrosoftWindowsServerHPCPack'
    offer: 'WindowsServerHPCPack'
    sku: '2016U2CN-WS2012R2-Excel'
    version: 'latest'
  }
  WindowsServer2016WithExcel: {
    publisher: 'MicrosoftWindowsServerHPCPack'
    offer: 'WindowsServerHPCPack'
    sku: '2016U2CN-WS2016-Excel'
    version: 'latest'
  }
  WindowsServer2012_Gen2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-datacenter-gensecond'
    version: 'latest'
  }
  WindowsServer2012R2_Gen2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-r2-datacenter-gensecond'
    version: 'latest'
  }
  WindowsServer2016_Gen2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2016-datacenter-gensecond'
    version: 'latest'
  }
  WindowsServer2019_Gen2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-datacenter-gensecond'
    version: 'latest'
  }
  WindowsServer2022_Gen2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-g2'
    version: 'latest'
  }
  CustomImage: {
    id: trim(computeNodeImageResourceId)
  }
}
var headNodeImageRef = headNodeImages[headNodeOS]
var computeNodeImageRef = computeNodeImages[computeNodeImage]
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

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
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

module dc 'shared/domain-controller.bicep' = {
  name: 'dc'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    domainName: _domainName
    nicName: dcNICName
    subnetID: subnetRef
    vmName: dcVMName
    vmSize: dcSize
  }
}

module updateVNetDNS 'shared/vnet-with-dns.bicep' = {
  name: 'updateVNetDNS'
  scope: resourceGroup()
  dependsOn: [
    vnet
    dc
  ]
  params: {
    vNetName: virtualNetworkName
    addressPrefix: addressPrefix
    subnetName: subnet1Name
    subnetPrefix: subnet1Prefix
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
    certSecrets: certSecrets
    clusterName: _clusterName
    createPublicIp: createPublicIPAddressForHeadNode == 'Yes'
    domainName: _domainName
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
    nsgName: createPublicIPAddressForHeadNode == 'Yes' ? nsg.name : null
    publicIPSuffix: publicIPSuffix
    subnetId: subnetRef
    vaultName: _vaultName
    vaultResourceGroup: _vaultResourceGroup
  }
  dependsOn: [
    updateVNetDNS
  ]
}

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
          UserName: '${_domainName}\\${adminUsername}'
          Password: adminPassword
        }
        AzureStorageConnString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccount.id,'2019-04-01').keys[0].value}'
      }
    }
  }
  dependsOn: [
    headNode
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
      imageOsPlatform: 'windows'
      adminUsername: adminUsername
      adminPassword: adminPassword
      availabilitySetName: (createCNInAVSet ? availabilitySetName : '')
      vmPriority: vmPriority
      installRDMADriver: (cnRDMACapable && autoEnableInfiniBand)
      enableAcceleratedNetworking: (enableAcceleratedNetworking == 'Yes')
      secrets: certSecrets
      certThumbprint: _certThumbprint
      headNodeList: _clusterName
      joinDomain: true
      domainName: _domainName
    }
    dependsOn: [
      availabilitySet
      updateVNetDNS
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
    secrets: certSecrets
    certThumbprint: _certThumbprint
    headNodeList: _clusterName
    joinDomain: true
    domainName: _domainName
  }
  dependsOn: [
    updateVNetDNS
  ]
}

output clusterDNSName string = (createPublicIPAddressForHeadNode == 'No') ? privateClusterFQDN : headNode.outputs.dnsName
