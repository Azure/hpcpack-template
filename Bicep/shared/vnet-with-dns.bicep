param vNetName string
param addressPrefix string
param subnetName string
param subnetPrefix string

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
        '10.0.0.4' //This is the static IP of DC. TODO: Make a parameter for it.
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
