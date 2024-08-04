param name string = 'azuremonitor'
param location string = resourceGroup().location

var uniqStr = uniqueString(resourceGroup().id)
var prefix = '${name}-${uniqStr}-'
var workSpaceName = '${prefix}workspace'

resource workSpace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workSpaceName
  location: location
}

module logIngestion 'log-ingestion.bicep' = {
  name: 'logIngestion'
  params: {
    workSpaceName: workSpace.name
    prefix: prefix
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
output logDcrStreamName string = logIngestion.outputs.dcrStreamName
output logUserMiClientId string = logIngestion.outputs.userMiClientId
output logUserMiResId string = logIngestion.outputs.userMiResId
