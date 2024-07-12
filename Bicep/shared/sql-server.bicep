import { sharedResxBaseUrl } from 'types-and-vars.bicep'

param subnetId string
param vmName string
param vmSize string
param diskType string
param domainName string
param adminUsername string
@secure()
param adminPassword string
param availabilitySetName string
param enableAcceleratedNetworking bool
param SqlDscExtName string

module sqlServer 'windows-vm-dsc.bicep' = {
  name: 'createDBServer${vmName}'
  params: {
    subnetId: subnetId
    vmName: vmName
    vmSize: vmSize
    osDiskType: diskType
    imageReference: {
      publisher: 'MicrosoftSQLServer'
      offer: 'sql2019-ws2022'
      sku: 'Standard'
      version: 'latest'
    }
    adminUsername: adminUsername
    adminPassword: adminPassword
    availabilitySetName: availabilitySetName
    dataDiskCount: 1
    dataDiskSizeInGB: 200
    dataDiskType: diskType
    enableAcceleratedNetworking: enableAcceleratedNetworking
    dscExtensionName: SqlDscExtName
    dscSettings: {
      configuration: {
        url: '${sharedResxBaseUrl}/ConfigSQLServer.ps1.zip'
        script: 'ConfigSQLServer.ps1'
        function: 'ConfigSQLServer'
      }
    }
    dscProtectedSettings: {}
  }
}

resource sqlVM 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: vmName
}

resource joinADDomain 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: sqlVM
  name: 'JoinADDomain'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      User: '${domainName}\\${adminUsername}'
      NumberOfRetries: '50'
      RetryIntervalInMilliseconds: '10000'
      Restart: 'true'
      Options: '3'
    }
    protectedSettings: {
      Password: adminPassword
    }
  }
  dependsOn: [
    sqlServer
  ]
}
