@description('The VM name')
param vmName string

@description('The name of the Dsc extension')
param dscExtensionName string = 'configNodeWithDsc'

@description('The DSC public settings')
param dscSettings object

@description('The DSC protected settings')
@secure()
param dscProtectedSettings object = {}

resource dscExtension 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  name: '${vmName}/${dscExtensionName}'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.80'
    autoUpgradeMinorVersion: true
    settings: dscSettings
    protectedSettings: dscProtectedSettings
  }
}
