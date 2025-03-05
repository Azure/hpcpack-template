param vNetName string
param vNetAddressPrefix string = '10.0.0.0/16'
param subnetName string = 'Subnet-1'
param subnetAddressPrefix string = '10.0.0.0/22'
@secure()
param adminPassword string
param adminUsername string = 'hpcadmin'
param domainName string = 'hpc.cluster'
param dcVmName string
param dcSize string = 'Standard_D2_v3'
@secure()
param domainPassword string

var vnetId = vnet.outputs.vNetId
var subnetRef = '${vnetId}/subnets/${subnetName}'

module vnet 'vnet.bicep' = {
  name: 'createVNet'
  scope: resourceGroup()
  params: {
    vNetName: vNetName
    addressPrefix: vNetAddressPrefix
    subnetName: subnetName
    subnetPrefix: subnetAddressPrefix
  }
}

module dc 'domain-controller.bicep' = {
  name: 'dc'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    domainName: domainName
    subnetId: subnetRef
    vmName: dcVmName
    vmSize: dcSize
    domainPassword: domainPassword
  }
}

module updateVNetDNS 'vnet.bicep' = {
  name: 'updateVNetDNS'
  params: {
    vNetName: vNetName
    addressPrefix: vNetAddressPrefix
    subnetName: subnetName
    subnetPrefix: subnetAddressPrefix
    dnsSeverIp: '10.0.0.4'
  }
  dependsOn: [
    vnet
    dc
  ]
}

output vNetId string = vnetId
