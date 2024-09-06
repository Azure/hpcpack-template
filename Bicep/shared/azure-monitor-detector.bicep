import { AzureMonitorLogSettings } from 'types-and-vars.bicep'

param vmName string

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: vmName
}

var tags = vm.tags
var logEndpoint = tags.LA_DceUrl
var logDcrRunId = tags.LA_DcrId
var logDcrStreamName = tags.LA_DcrStream
var logUserMiClientId = tags.LA_MiClientId
var logUserMiResId = tags.LA_MiResId
var logEnabled = !empty(logEndpoint) && !empty(logDcrRunId) && !empty(logDcrStreamName) && !empty(logUserMiClientId) && !empty(logUserMiResId)

output logSettings AzureMonitorLogSettings? = logEnabled ? {
  LA_DceUrl: logEndpoint
  LA_DcrId: logDcrRunId
  LA_DcrStream: logDcrStreamName
  LA_MiClientId: logUserMiClientId
  LA_MiResId: logUserMiResId
} : null
