param vmName string
param location string = resourceGroup().location
param userAssignedManagedIdentity string

resource ma 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: '${vmName}/AzureMonitorLinuxAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.21'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      authentication: {
        managedIdentity: {
          'identifier-name': 'mi_res_id'
          'identifier-value': userAssignedManagedIdentity
        }
      }
    }
  }
}

resource da 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: '${vmName}/DAExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
    settings: {
      enableAMA: 'true'
    }
  }
  dependsOn: [
    ma
  ]
}
