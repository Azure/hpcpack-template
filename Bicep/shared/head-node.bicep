import { diskTypes, AzureMonitorLogSettings, AzureMonitorAgentSettings, CertificateSettings, certSecretForWindows, certSettingsToVmTags } from 'types-and-vars.bicep'

param hnName string

//Network settings

//TODO: Either get vnet rg and name from subnetId, or use params vnetRg, vnetName and vnetSubnet
//instead of a single param subnetId.
param externalVNetRg string?
param externalVNetName string?
param subnetId string

param enableAcceleratedNetworking bool
param createPublicIp bool
param lbName string?
param lbPoolName string?
param nsgName string?
param privateIp string?

//VM settings
param enableManagedIdentity bool
param hnAvSetName string?
param hnVMSize string
param adminUsername string
@secure()
param adminPassword string
param certSettings CertificateSettings
param hnImageRef object
param hnDataDiskCount int
param hnDataDiskSize int
param hnOsDiskType string
param hnDataDiskType string

//For Azure Monitor Log
param logSettings AzureMonitorLogSettings?
param amaSettings AzureMonitorAgentSettings?

//Role assignment settings
param clusterName string

//VM extension settings
param installIBDriver bool
param domainName string?
param domainOUPath string = ''

//IaaS settings
param iaasResourceGroupName string

@description('URL to the VSTS Configure WinRM script')
param configureWinRMUri string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/demos/vm-winrm-windows/ConfigureWinRM.ps1'

@description('URL to the VSTS MakeCert executable')
param makeCertExeUri string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/501dc7d24537e820df7c80bce51aba9674233b2b/201-vm-winrm-windows/makecert.exe'

@description('Command to execute the Configure WinRM script')
param scriptCommand string = 'powershell.exe -ExecutionPolicy RemoteSigned -File ConfigureWinRM.ps1 '

@description('URL to the addBVTUserScriptUri script')
param addBVTUserScriptUri string = 'https://raw.githubusercontent.com/Azure/hpcpack-template/bicep-bvt/SharedResources/Generated/AddBVTUser.ps1'

@description('Command to execute the Add BVT User script')
param addBVTUserScriptCommand string = 'powershell.exe -ExecutionPolicy RemoteSigned -File AddBVTUser.ps1 '

@secure()
param domainPassword string

var useExternalVNet = !empty(externalVNetName) && !empty(externalVNetRg)

var publicIpSuffix = uniqueString(resourceGroup().id)
var nicSuffix = '-nic-${uniqueString(subnetId)}'

var vaultResourceGroup = certSettings.vaultResourceGroup
var vaultName = certSettings.vaultName

var certTags = certSettingsToVmTags(certSettings)
var tags = union(certTags, empty(logSettings) ? {} : logSettings!)
var userMiResIdForLog = empty(logSettings) ? null : logSettings!.LA_MiResId

var systemIdentity = {
  type: 'SystemAssigned'
}
var userIdentity = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${userMiResIdForLog}': {}
  }
}
var systemAndUserIdentities = {
  type: 'SystemAssigned, UserAssigned'
  userAssignedIdentities: {
    '${userMiResIdForLog}': {}
  }
}
var identity = !enableManagedIdentity && empty(userMiResIdForLog)
  ? null
  : (enableManagedIdentity && !empty(userMiResIdForLog) ? systemAndUserIdentities : (enableManagedIdentity ? systemIdentity : userIdentity))

var hnDataDisks = [
  for j in range(0, ((hnDataDiskCount == 0) ? 1 : hnDataDiskCount)): {
    lun: j
    createOption: 'Empty'
    diskSizeGB: hnDataDiskSize
    managedDisk: {
      storageAccountType: diskTypes[hnDataDiskType]
    }
  }
]

//NOTE: Even if lbName is null, we have to provide a valid string for the resource name.
//This seems stupid but it's required by ARM! The same rule applies to the following resources nsg and avSet.
resource lb 'Microsoft.Network/loadBalancers@2023-11-01' existing = if (!empty(lbName)) {
  name: empty(lbName) ? 'lbName' : lbName!
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' existing = if (!empty(nsgName)) {
  name: empty(nsgName) ? 'nsgName' : nsgName!
}

resource allowWinRmRule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-05-01' = {
  name: 'Allow-WinRM'
  parent: nsg
  properties: {
    priority: 900
    access: 'Allow'
    direction: 'Inbound'
    protocol: '*'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '5986'
  }
}

resource avSet 'Microsoft.Compute/availabilitySets@2024-03-01' existing = if (!empty(hnAvSetName)) {
  name: empty(hnAvSetName) ? 'hnAvSetName' : hnAvSetName!
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (createPublicIp) {
  name: '${hnName}PublicIp'
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${hnName}${publicIpSuffix}')
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' =  {
  name: '${hnName}${nicSuffix}'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'IPConfig'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: empty(privateIp) ? 'Dynamic' : 'Static'
          privateIPAddress: privateIp
          publicIPAddress: !createPublicIp ? null : {
            id: publicIp.id
          }
          loadBalancerBackendAddressPools: empty(lbName) ? null : [
            {
              id: '${lb.id}/backendAddressPools/${lbPoolName}'
            }
          ]
          loadBalancerInboundNatRules: empty(lbName) ? null : [
            {
              id: '${lb.id}/inboundNatRules/RDP-${hnName}'
            }
          ]
        }
      }
    ]
    networkSecurityGroup: empty(nsgName) ? null : {
      id: nsg.id
    }
    enableAcceleratedNetworking: enableAcceleratedNetworking
  }
}

resource headNode 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: hnName
  location: resourceGroup().location
  identity: identity
  tags: tags
  properties: {
    availabilitySet: empty(hnAvSetName) ? null : {
      id: avSet.id
    }
    hardwareProfile: {
      vmSize: hnVMSize
    }
    osProfile: {
      computerName: hnName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
      }
      secrets: [
        certSecretForWindows(certSettings.vaultResourceGroup, certSettings.vaultName, certSettings.url)
      ]
    }
    storageProfile: {
      imageReference: hnImageRef
      osDisk: {
        name: '${hnName}-osdisk'
        caching: 'ReadOnly'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskTypes[hnOsDiskType]
        }
      }
      dataDisks: ((hnDataDiskCount == 0) ? [] : hnDataDisks)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableManagedIdentity) {
  name: guid(resourceGroup().id, clusterName, hnName)
  scope: resourceGroup()
  properties: {
    //Contributor Role
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: headNode.identity.principalId
  }
}

module roleAssignmentC1Module 'role-assignment.bicep' = if (enableManagedIdentity) {
  name: guid(iaasResourceGroupName, clusterName, hnName)
  scope: resourceGroup(iaasResourceGroupName)
  params: {
    principalId: headNode.identity.principalId
    clusterName: clusterName
    hnName: hnName
  }
}

module keyVaultRoleAssignment 'key-vault-role-assignment.bicep' = if (enableManagedIdentity) {
  name: 'msiKeyVaultRoleAssignment${hnName}'
  scope: resourceGroup(vaultResourceGroup)
  params: {
    keyVaultName: vaultName
    principalId: headNode.identity.principalId
  }
}

module vnetRoleAssignment 'vnet-role-assignment.bicep' = if (useExternalVNet) {
  name: 'msiVNetRoleAssignment${hnName}'
  //NOTE: To pass stupid ARM validation even when useExternalVNet is false.
  scope: resourceGroup(useExternalVNet ? externalVNetRg! : 'externalVNetRg')
  params: {
    vnetName: externalVNetName!
    principalId: headNode.identity.principalId
  }
}

resource ibDriver 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (installIBDriver) {
  parent: headNode
  name: 'installInfiniBandDriver'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'InfiniBandDriverWindows'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
  }
}

resource joinDomain 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (!empty(domainName)) {
  parent: headNode
  name: 'JoinADDomain'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      OUPath: domainOUPath
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
    ibDriver
  ]
}

var isPublicIpCreated = createPublicIp && !empty(publicIpSuffix)

resource winrmScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (isPublicIpCreated) {
  name: 'WinRMConfigScript'
  location: resourceGroup().location
  parent: headNode
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        configureWinRMUri
        makeCertExeUri
      ]
    }
    protectedSettings: {
      commandToExecute: '${scriptCommand}${publicIp.properties.dnsSettings.fqdn}'
    }
  }
}

module ama '../Shared/ama-windows.bicep' = if (!empty(amaSettings)) {
  name: '${hnName}-windowsAMA'
  params: {
    dcrResId: empty(amaSettings) ? '' : amaSettings!.dcrResId
    userMiResId: empty(amaSettings) ? '' : amaSettings!.userMiResId
    vmName: hnName
  }
  dependsOn: [
    headNode
  ]
}

output fqdn string = createPublicIp ? publicIp.properties.dnsSettings.fqdn : ''

resource addBVTUserScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: headNode
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
