import { CertificateSettings, isValidCertificateSettings, vmTagsToCertSettings } from 'types-and-vars.bicep'

param vmName string

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: vmName
}

var tags = vm.tags
var settings = vmTagsToCertSettings(tags)
var hasSettings = isValidCertificateSettings(settings)

output certSettings CertificateSettings? = hasSettings ? settings : null
