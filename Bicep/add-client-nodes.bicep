import { WindowsComputeNodeImage, windowsComputeNodeImages, DiskType, diskTypes, DiskCount, DiskSizeInGB, YesOrNo, YesOrNoOrAuto, sharedResxBaseUrl } from 'shared/types-and-vars.bicep'

@minLength(1)
@maxLength(12)
param nodeNamePrefix string

param nodeNameStartIndex int = 0

@minValue(1)
@maxValue(50)
param nodeNumber int = 1

param nodeImage WindowsComputeNodeImage = 'WindowsServer2019'

param nodeVMSize string = 'Standard_D3_v2'

param nodeOsDiskType DiskType = 'Standard_SSD'

param dataDiskCount DiskCount = 1

param dataDiskSizeInGB DiskSizeInGB = 128

param dataDiskType DiskType = 'Standard_SSD'

param adminUsername string

@secure()
param adminUserPassword string

@description('The existing virtual network')
param virtualNetworkName string

@description('The resource group in which the existing virtual network was created.')
param virtualNetworkResourceGroupName string

@description('The existing subnet in which all VMs of the client nodes will be created.')
param subnetName string

@description('Specify the fully qualified domain name (FQDN) for the existing domain forest if your HPC cluster is domain joined, for example \'hpc.cluster\'.')
param domainName string = ''

@description('The organizational unit (OU) in the domain, for example \'OU=testOU,DC=domain,DC=Domain,DC=com\', used only when \'domainName\' is specified.')
param domainOUPath string = ''


var nodeImages = windowsComputeNodeImages
var nodeImageRef = nodeImages[nodeImage]

module clientNodes 'shared/client-node.bicep' = [
  for i in range(nodeNameStartIndex, nodeNumber): {
    name: '${nodeNamePrefix}${padLeft(i, 3, '0')}'
    params: {
      vmName: '${nodeNamePrefix}${padLeft(i, 3, '0')}'
      vmImage: nodeImageRef
      vmSize: nodeVMSize
      vmOsDiskType: nodeOsDiskType
      vmDataDiskCount: dataDiskCount
      vmDataDiskSize: dataDiskSizeInGB
      vmDataDiskType: dataDiskType
      username: adminUsername
      password: adminUserPassword
      domainName: domainName
      domainOUPath: domainOUPath
      vnetRg: virtualNetworkResourceGroupName
      vnetName: virtualNetworkName
      subnetName: subnetName
    }
  }
]
