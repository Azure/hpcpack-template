param name string
param location string = resourceGroup().location

var uniqStr = uniqueString(resourceGroup().id)
var logSpaceName = '${name}${uniqStr}-workspace'

resource logSpace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logSpaceName
  location: location
}

module dcr 'data-collection-rules.bicep' = {
  name: 'dataCollectionRules'
  params: {
    WorkspaceLocation: location
    WorkspaceResourceId: logSpace.id
  }
}

resource userMi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'userIdentityForMonitorAgent'
  location: location
}

output userMiId string = userMi.id
output workSpaceId string = logSpace.id
