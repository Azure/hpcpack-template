param workSpaceName string
param name string = 'setup'
param location string = resourceGroup().location

var uniqStr = uniqueString(resourceGroup().id)
var prefix = '${name}${uniqStr}'
var dcrName = '${prefix}-dcr-logIngestionApi'

resource workSpace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workSpaceName
}

module customTable 'custom-la-table.bicep' = {
  name: '${prefix}-log-ingestion-customTable'
  params: {
    name: name
    workSpaceName: workSpace.name
  }
}

resource dce 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = {
  name: '${prefix}-log-ingestion-dce'
  location: location
  properties: {
  }
}

resource userMi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${prefix}-log-ingestion-userMi'
  location: location
}

module dcr 'dcr-log-ingestion.bicep' = {
  name: '${prefix}-log-ingestion-dcr'
  params: {
    dataCollectionRuleName: dcrName
    workspaceResId: workSpace.id
    dataCollectionEndpointId: dce.id
    userMiPrincipalIds: [
      userMi.properties.principalId
    ]
  }
  dependsOn: [
    customTable
  ]
}

output logsIngestionEndpoint string = dce.properties.logsIngestion.endpoint
output dcrRunId string = dcr.outputs.dcrRunId
output userMiResId string = userMi.id
output userMiClientId string = userMi.properties.clientId
