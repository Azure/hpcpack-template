import { AzureMonitorLogSettings } from 'types-and-vars.bicep'

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

output logSettings AzureMonitorLogSettings = {
  LA_DceUrl: logIngestion.outputs.logsIngestionEndpoint
  LA_DcrId: logIngestion.outputs.dcrRunId
  LA_DcrStream: logIngestion.outputs.dcrStreamName
  LA_MiClientId: logIngestion.outputs.userMiClientId
  LA_MiResId: logIngestion.outputs.userMiResId
}
