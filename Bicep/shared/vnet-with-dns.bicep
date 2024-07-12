param vNetName string
param addressPrefix string
param subnetName string
param subnetPrefix string
param dnsSeverIp string = '10.0.0.4'

resource updateVNetDNS 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vNetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: [
        dnsSeverIp
        '8.8.8.8'
      ]
    }
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
