param name string = 'azuremonitor'
param location string = resourceGroup().location

var uniqStr = uniqueString(resourceGroup().id)
var workSpaceName = '${name}${uniqStr}-workspace'

resource workSpace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workSpaceName
  location: location
}

module logIngestion 'log-ingestion.bicep' = {
  name: 'logIngestion'
  params: {
    workSpaceName: workSpace.name
    name: name
  }
}

module vmInsights 'vm-insights.bicep' = {
  name: 'vmInsights'
  params: {
    workSpaceName: workSpace.name
  }
}

output logEndpoint string = logIngestion.outputs.logsIngestionEndpoint
output logDcrRunId string = logIngestion.outputs.dcrRunId
output logUserMiClientId string = logIngestion.outputs.userMiClientId
