param vmName string
param location string = resourceGroup().location
param userAssignedManagedIdentity string
param dataCollectionRuleId string

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: vmName
}

resource dcrAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2019-11-01-preview' = {
  scope: vm
  name: '${vmName}-Dcr-Association'
  properties: {
    description: 'Association of data collection rule for VM Insights.'
    dataCollectionRuleId: dataCollectionRuleId
  }
}

resource ma 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  parent: vm
  name: 'AzureMonitorWindowsAgent'
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
  dependsOn: [
    dcrAssociation
  ]
}

resource da 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: vm
  name: 'DAExtension'
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
