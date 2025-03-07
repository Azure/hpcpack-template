import { sharedResxBaseUrl } from 'types-and-vars.bicep'

param subnetId string
param ip string = '10.0.0.4'
param vmName string
param vmSize string
param adminUsername string
@secure()
param adminPassword string
param domainName string

@description('URL to the addBVTUserScriptUri script')
param addBVTUserScriptUri string = 'https://raw.githubusercontent.com/Azure/hpcpack-template/bicep-bvt/SharedResources/Generated/AddBVTUser.ps1'

@description('Command to execute the Add BVT User script')
param addBVTUserScriptCommand string = 'powershell.exe -ExecutionPolicy RemoteSigned -File AddBVTUser.ps1 '

@secure()
param domainPassword string

var nicName = '${vmName}-nic-${uniqueString(subnetId)}'

resource dcNIC 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: nicName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'IPConfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: ip
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource dcVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadOnly'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: [
        {
          name: '${vmName}-datadisk'
          caching: 'None'
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
          diskSizeGB: 200
          lun: 0
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: dcNIC.id
        }
      ]
    }
  }
}

resource promoteDC 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: dcVM
  name: 'promoteDomainController'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.80'
    autoUpgradeMinorVersion: true
    settings: {
      configuration: {
        url: '${sharedResxBaseUrl}/CreateADPDC.ps1.zip'
        script: 'CreateADPDC.ps1'
        function: 'CreateADPDC'
      }
      configurationArguments: {
        DomainName: domainName
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

resource addBVTUserScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: dcVM
  name: 'addBVTUserScript'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        addBVTUserScriptUri
      ]
    }
    protectedSettings: {
      commandToExecute: '${addBVTUserScriptCommand}${domainPassword}'
    }
  }
}
