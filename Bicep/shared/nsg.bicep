param name string

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: name
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
