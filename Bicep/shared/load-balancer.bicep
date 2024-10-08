param publicIpName string
param publicIpDnsNameLabel string
param lbName string
param lbPoolName string
param hnNames string[]

var lbId = resourceId('Microsoft.Network/loadBalancers', lbName)
var lbFrontEndIPConfigId = '${lbId}/frontendIPConfigurations/LoadBalancerFrontEnd'
var lbPoolId = '${lbId}/backendAddressPools/${lbPoolName}'
var lbProbeId = '${lbId}/probes/tcpProbe'

resource lbPublicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: publicIpName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: publicIpDnsNameLabel
    }
  }
}

resource lb 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: lbName
  location: resourceGroup().location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: lbPublicIp.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbPoolName
      }
    ]
    inboundNatRules: [
      for (hnName, i) in hnNames: {
        name: 'RDP-${hnName}'
        properties: {
          frontendIPConfiguration: {
            id: lbFrontEndIPConfigId
          }
          protocol: 'Tcp'
          frontendPort: 50001 + i
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: lbFrontEndIPConfigId
          }
          backendAddressPool: {
            id: lbPoolId
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: lbProbeId
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 5802
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

output fqdn string = lbPublicIp.properties.dnsSettings.fqdn
