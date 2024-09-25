import { AzureMonitorLogSettings, AzureMonitorAgentSettings } from 'types-and-vars.bicep'

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

// Disable VM Insights for now since the official Azure Policy for it is buggy as of this writing.
// module vmInsights 'vm-insights.bicep' = {
//   name: 'vmInsights'
//   params: {
//     workSpaceName: workSpace.name
//   }
// }

//User MI for Azure Monitor Agent, which is to be setup on each VM in Bicep, without Azure Policy.
resource userMiForAma 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'userMiForMa'
  location: location
}

module dcrForWinEvents 'dcr-win-events.bicep' = {
  name: 'dataCollectionRules'
  params: {
    workspaceLocation: location
    workspaceResourceId: workSpace.id
  }
}

output logSettings AzureMonitorLogSettings = {
  LA_DceUrl: logIngestion.outputs.logsIngestionEndpoint
  LA_DcrId: logIngestion.outputs.dcrRunId
  LA_DcrStream: logIngestion.outputs.dcrStreamName
  LA_MiClientId: logIngestion.outputs.userMiClientId
  LA_MiResId: logIngestion.outputs.userMiResId
}

output amaSettings AzureMonitorAgentSettings = {
  userMiResId: userMiForAma.id
  dcrResId: dcrForWinEvents.outputs.dcrResId
}
