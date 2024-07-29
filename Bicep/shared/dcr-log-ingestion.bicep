param dataCollectionRuleName string
param location string = resourceGroup().location
param workspaceResId string
param dataCollectionEndpointId string?
param userMiPrincipalIds string[] = []

resource logIngestionDcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dataCollectionRuleName
  location: location
  kind: 'Direct'
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointId
    streamDeclarations: {
      'Custom-HPCPack': {
        columns: [
          {
            name: 'TimeGenerated'
            type: 'datetime'
          }
          {
            name: 'Computer'
            type: 'string'
          }
          {
            name: 'Service'
            type: 'string'
          }
          {
            name: 'Process'
            type: 'int'
          }
          {
            name: 'Level'
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
          'Custom-HPCPack'
        ]
        destinations: [
          'myworkspace'
        ]
        outputStream: 'Custom-HPCPack_CL'
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
