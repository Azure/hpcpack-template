param vmName string
param location string = resourceGroup().location
param dcrResId string
param userMiResId string
param installDependencyAgent bool = false

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: vmName
}

resource dcrAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2019-11-01-preview' = {
  scope: vm
  name: '${vmName}-Dcr-Association'
  properties: {
    description: 'Association of data collection rule for VM Insights.'
    dataCollectionRuleId: dcrResId
  }
}

resource ma 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  parent: vm
  name: 'AzureMonitorLinuxAgent'
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
          'identifier-value': userMiResId
        }
      }
    }
  }
  dependsOn: [
    dcrAssociation
  ]
}

resource da 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = if (installDependencyAgent) {
  parent: vm
  name: 'DependencyAgentLinux'
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
