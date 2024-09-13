param vNetName string
param vNetAddressPrefix string
param subnetName string
param subnetAddressPrefix string
@secure()
param adminPassword string
param adminUsername string
param domainName string
param dcVmName string
param dcSize string

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
