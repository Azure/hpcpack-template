import { sharedResxBaseUrl } from 'types-and-vars.bicep'

param sqlVmName string
param SqlVmExtName string
param domainName string
param headNodeList string
param adminUsername string
@secure()
param adminPassword string

resource dscExtension 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  name: '${sqlVmName}/${SqlVmExtName}'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.80'
    autoUpgradeMinorVersion: true
    settings: {
      configuration: {
        url: '${sharedResxBaseUrl}/ConfigDBPermissions.ps1.zip'
        script: 'ConfigDBPermissions.ps1'
        function: 'ConfigDBPermissions'
      }
      configurationArguments: {
        DomainName: domainName
        HeadNodeList: headNodeList
      }
    }
    protectedSettings: {
      configurationArguments: {
        AdminCreds: {
          UserName: adminUsername
          Password: adminPassword
        }
      }
    }
  }
}
