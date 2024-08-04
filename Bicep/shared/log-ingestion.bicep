param workSpaceName string
param prefix string
param location string = resourceGroup().location

resource workSpace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workSpaceName
}

module customTable 'custom-la-table.bicep' = {
  name: '${prefix}logIngestionCustomTable'
  params: {
    prefix: prefix
    workSpaceName: workSpace.name
  }
}

resource dce 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = {
  name: '${prefix}logIngestionDce'
  location: location
  properties: {
  }
}

resource userMi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${prefix}logIngestionUserMi'
  location: location
}

module dcr 'dcr-log-ingestion.bicep' = {
  name: '${prefix}logIngestionDcr'
  params: {
    dataCollectionRuleName: '${prefix}dcrLogIngestionApi'
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
output dcrStreamName string = dcr.outputs.dcrStreamName
output userMiResId string = userMi.id
output userMiClientId string = userMi.properties.clientId
