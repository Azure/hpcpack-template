param vNetName string
param addressPrefix string
param subnetName string
param subnetPrefix string
param dnsSeverIp string?

var dhcpOpts = empty(dnsSeverIp) ? null : {
  dnsServers: [
    dnsSeverIp!
    '8.8.8.8'
  ]
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vNetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    dhcpOptions: dhcpOpts
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

output vNetId string = vnet.id
