@description('Workspace Resource ID.')
param workspaceResourceId string

@description('Workspace Location.')
param workspaceLocation string

resource dcr 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
  name: 'dcrForSystemLog'
  location: workspaceLocation
  properties: {
    description: 'Data collection rule for Windows Event log or Linux Syslog'
    dataSources: {
      windowsEventLogs: [
        {
          name: 'Application'
          streams: [
            'Microsoft-Event'
          ]
          scheduledTransferPeriod: 'PT1M'
          xPathQueries: [
            'Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0)]]'
          ]
        }
        {
          name: 'Microsoft_HPC_Pack'
          streams: [
            'Microsoft-Event'
          ]
          scheduledTransferPeriod: 'PT1M'
          xPathQueries: [
            '"Microsoft HPC Pack"!*'
          ]
        }
        {
          name: 'Windows_HPC_Server'
          streams: [
            'Microsoft-Event'
          ]
          scheduledTransferPeriod: 'PT1M'
          xPathQueries: [
            '"Windows HPC Server"!*'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspaceResourceId
          name: 'myWorkspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Event'
        ]
        destinations: [
          'myWorkspace'
        ]
      }
    ]
  }
}

output dcrResId string = dcr.id
