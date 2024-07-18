param vmName string
param location string = resourceGroup().location
param userAssignedManagedIdentity string

resource ma 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: '${vmName}/AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
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

resource da 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  name: '${vmName}/DAExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.10'
    autoUpgradeMinorVersion: true
    settings: {
      enableAMA: 'true'
    }
  }
  dependsOn: [
    //TODO: is this required?
    ma
  ]
}
