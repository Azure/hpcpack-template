@description('Workspace Resource ID.')
param WorkspaceResourceId string

@description('Workspace Location.')
param WorkspaceLocation string

@description('This is the name of the AMA-VMI Data Collection Rule(DCR)')
@metadata({ displayName: 'Name of the Data Collection Rule(DCR)' })
param userGivenDcrName string = 'ama-vmi-default-perfAndda-dcr'

resource PerfDataDcr 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
  name: 'MSVMI-PerfandDa-${userGivenDcrName}'
  location: WorkspaceLocation
  properties: {
    description: 'Data collection rule for VM Insights.'
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          scheduledTransferPeriod: 'PT1M'
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\VmInsights\\DetailedMetrics'
          ]
        }
      ]
      extensions: [
        {
          name: 'DependencyAgentDataSource'
          streams: [
            'Microsoft-ServiceMap'
          ]
          extensionName: 'DependencyAgent'
          extensionSettings: {}
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: WorkspaceResourceId
          name: 'VMInsightsPerf-Logs-Dest'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
      {
        streams: [
          'Microsoft-ServiceMap'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
    ]
  }
}

output dataCollectionRuleId string = PerfDataDcr.id
