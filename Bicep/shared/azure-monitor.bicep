param name string
param location string = resourceGroup().location

var uniqStr = uniqueString(resourceGroup().id)
var workSpaceName = '${name}${uniqStr}-workspace'

resource workSpace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workSpaceName
  location: location
}

module dcr 'data-collection-rules.bicep' = {
  name: 'dataCollectionRules'
  params: {
    WorkspaceLocation: location
    WorkspaceResourceId: workSpace.id
  }
}

resource userMi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'userIdentityForMonitorAgent'
  location: location
}

output userMiId string = userMi.id
output workSpaceId string = workSpace.id
output dcrId string = dcr.outputs.dcrId
