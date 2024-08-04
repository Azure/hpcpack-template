param dataCollectionRuleName string
param location string = resourceGroup().location
param workspaceResId string
param dataCollectionEndpointId string?
param userMiPrincipalIds string[] = []

var dcrStreamName = 'Custom-TraceListener'

resource logIngestionDcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dataCollectionRuleName
  location: location
  kind: 'Direct'
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointId
    streamDeclarations: {
      '${dcrStreamName}': {
        columns: [
          {
            name: 'Time'
            type: 'datetime'
          }
          {
            name: 'ComputerName'
            type: 'string'
          }
          {
            name: 'ProcessName'
            type: 'string'
          }
          {
            name: 'ProcessId'
            type: 'int'
          }
          {
            name: 'EventType'
            type: 'string'
          }
          {
            name: 'Id'
            type: 'int'
          }
          {
            name: 'Source'
            type: 'string'
          }
          {
            name: 'Content'
            type: 'string'
          }
        ]
      }
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspaceResId
          name: 'myworkspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          dcrStreamName
        ]
        destinations: [
          'myworkspace'
        ]
        transformKql: 'source | project TimeGenerated = Time, ComputerName, ProcessName, ProcessId, EventType, EventId = Id, Source, Content'
        outputStream: 'Custom-TraceListener_CL'  //NOTE: The table name must match the name defined in the ps1 script.
      }
    ]
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (id, index) in userMiPrincipalIds: {
  name: guid(id, 'Monitoring Metrics Publisher')
  scope: logIngestionDcr
  properties: {
    //Monitoring Metrics Publisher
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb')
    principalId: id
    principalType: 'ServicePrincipal'
  }
}]

output dcrResId string = logIngestionDcr.id
output dcrRunId string = logIngestionDcr.properties.immutableId
output dcrStreamName string = dcrStreamName
