@export()
var sharedResxBaseUrl = 'https://raw.githubusercontent.com/Azure/hpcpack-template/master/SharedResources/Generated'

@export()
type OsType = 'windows' | 'linux'

@export()
type DiskType = 'Standard_HDD' | 'Standard_SSD' | 'Premium_SSD'

@export()
var diskTypes = {
  Standard_HDD: 'Standard_LRS'
  Standard_SSD: 'StandardSSD_LRS'
  Premium_SSD: 'Premium_LRS'
}

@export()
type DiskCount = 0 | 1 | 2 | 4 | 8

@export()
type DiskSizeInGB = 32 | 64 | 128 | 256 | 512 | 1024 | 2048 | 4096

@export()
type YesOrNo = 'Yes' | 'No'

@export()
type YesOrNoOrAuto = 'Yes' | 'No' | 'Auto'

@export()
type HpcPackRelease = '2019 Update 2' | '2019 Update 3'

@export()
type HeadNodeImage = 'WindowsServer2022' | 'WindowsServer2019' | 'CustomImage'

var headNodeImages = {
  '2019 Update 2': {
    WindowsServer2019: {
      publisher: 'MicrosoftWindowsServerHPCPack'
      offer: 'WindowsServerHPCPack'
      sku: '2019hn-ws2019'
      version: '6.2.7756'
    }
    WindowsServer2022: {
      publisher: 'MicrosoftWindowsServerHPCPack'
      offer: 'WindowsServerHPCPack'
      sku: '2019hn-ws2022'
      version: '6.2.7756'
    }
    CustomImage: {}
  }
  '2019 Update 3': {
    WindowsServer2019: {
      publisher: 'MicrosoftWindowsServerHPCPack'
      offer: 'WindowsServerHPCPack'
      sku: '2019hn-ws2019'
      version: 'latest'
    }
    WindowsServer2022: {
      publisher: 'MicrosoftWindowsServerHPCPack'
      offer: 'WindowsServerHPCPack'
      sku: '2019hn-ws2022'
      version: 'latest'
    }
    CustomImage: {}
  }
}

@export()
func getHeadNodeImageRef(release HpcPackRelease, imageName HeadNodeImage, customImageId string?) object =>
  union(headNodeImages[release], {
    CustomImage: {
      id: customImageId
    }
  })[imageName]

@export()
type WindowsComputeNodeImage =
  | 'WindowsServer2012'
  | 'WindowsServer2012R2'
  | 'WindowsServer2016'
  | 'WindowsServer2019'
  | 'WindowsServer2022'
  | 'WindowsServer2012R2WithExcel'
  | 'WindowsServer2016WithExcel'
  | 'WindowsServer2012_Gen2'
  | 'WindowsServer2012R2_Gen2'
  | 'WindowsServer2016_Gen2'
  | 'WindowsServer2019_Gen2'
  | 'WindowsServer2022_Gen2'
  | 'CustomImage'
//End of WindowsComputeNodeImage

@export()
var windowsComputeNodeImages = {
  WindowsServer2008R2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2008-R2-SP1'
    version: 'latest'
  }
  WindowsServer2012: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-Datacenter'
    version: 'latest'
  }
  WindowsServer2012R2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-R2-Datacenter'
    version: 'latest'
  }
  WindowsServer2016: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2016-Datacenter'
    version: 'latest'
  }
  WindowsServer2019: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-Datacenter'
    version: 'latest'
  }
  WindowsServer2022: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter'
    version: 'latest'
  }
  WindowsServer2012R2WithExcel: {
    publisher: 'MicrosoftWindowsServerHPCPack'
    offer: 'WindowsServerHPCPack'
    sku: '2016U2CN-WS2012R2-Excel'
    version: 'latest'
  }
  WindowsServer2016WithExcel: {
    publisher: 'MicrosoftWindowsServerHPCPack'
    offer: 'WindowsServerHPCPack'
    sku: '2016U2CN-WS2016-Excel'
    version: 'latest'
  }
  WindowsServer2012_Gen2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-datacenter-gensecond'
    version: 'latest'
  }
  WindowsServer2012R2_Gen2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-r2-datacenter-gensecond'
    version: 'latest'
  }
  WindowsServer2016_Gen2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2016-datacenter-gensecond'
    version: 'latest'
  }
  WindowsServer2019_Gen2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-datacenter-gensecond'
    version: 'latest'
  }
  WindowsServer2022_Gen2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-g2'
    version: 'latest'
  }
  CustomImage: {}
}

@export()
type LinuxComputeNodeImage =
  | 'CentOS_7.6'
  | 'CentOS_7.7'
  | 'CentOS_7.8'
  | 'CentOS_7.9'
  | 'CentOS_7.6_HPC'
  | 'CentOS_7.7_HPC'
  | 'CentOS_7.8_HPC'
  | 'CentOS_7.9_HPC'
  | 'CentOS_7.6_Gen2'
  | 'CentOS_7.7_Gen2'
  | 'CentOS_7.8_Gen2'
  | 'CentOS_7.9_Gen2'
  | 'CentOS_7.6_HPC_Gen2'
  | 'CentOS_7.7_HPC_Gen2'
  | 'CentOS_7.8_HPC_Gen2'
  | 'CentOS_7.9_HPC_Gen2'
  | 'AlmaLinux_8_Gen1'
  | 'AlmaLinux_8_Gen2'
  | 'AlmaLinux_9_Gen1'
  | 'AlmaLinux_9_Gen2'
  | 'AlmaLinux_8_HPC_Gen1'
  | 'AlmaLinux_8_HPC_Gen2'
  | 'Rocky_Linux_8_base'
  | 'Rocky_Linux_8_LVM'
  | 'Rocky_Linux_9_base'
  | 'Rocky_Linux_9_LVM'
  | 'RHEL_7.7'
  | 'RHEL_7.8'
  | 'RHEL_7.9'
  | 'RHEL_8.5'
  | 'RHEL_8.6'
  | 'RHEL_8.7'
  | 'RHEL_8.8'
  | 'RHEL_8.9'
  | 'RHEL_9.0'
  | 'RHEL_9.1'
  | 'RHEL_9.2'
  | 'RHEL_9.3'
  | 'RHEL_9.4'
  | 'RHEL_9.5'
  | 'RHEL_7.7_Gen2'
  | 'RHEL_7.8_Gen2'
  | 'RHEL_7.9_Gen2'
  | 'RHEL_8.5_Gen2'
  | 'RHEL_8.6_Gen2'
  | 'RHEL_8.7_Gen2'
  | 'RHEL_8.9_Gen2'
  | 'RHEL_9.0_Gen2'
  | 'RHEL_9.1_Gen2'
  | 'RHEL_9.2_Gen2'
  | 'RHEL_9.3_Gen2'
  | 'RHEL_9.4_Gen2'
  | 'RHEL_9.5_Gen2'
  | 'SLES_12_SP5'
  | 'SLES_12_SP5_HPC'
  | 'SLES_12_SP5_Gen2'
  | 'SLES_12_SP5_HPC_Gen2'
  | 'SLES_15_SP3_HPC'
  | 'Ubuntu_16.04'
  | 'Ubuntu_18.04'
  | 'Ubuntu_20.04'
  | 'Ubuntu_22.04'
  | 'Ubuntu_24.04'
  | 'Ubuntu_16.04_Gen2'
  | 'Ubuntu_18.04_Gen2'
  | 'Ubuntu_20.04_Gen2'
  | 'Ubuntu_22.04_Gen2'
  | 'Ubuntu_24.04_Gen2'
  | 'Ubuntu_18.04_HPC_Gen2'
  | 'Ubuntu_20.04_HPC_Gen2'
  | 'Ubuntu_22.04_HPC_Gen2'
  | 'CustomImage'
//End of LinuxComputeNodeImage

@export()
var linuxComputeNodeImages = {
  AlmaLinux_8_Gen1: {
    publisher: 'almalinux'
    offer: 'almalinux-x86_64'
    sku: '8-gen1'
    version: 'latest'
  }
  AlmaLinux_8_Gen2: {
    publisher: 'almalinux'
    offer: 'almalinux-x86_64'
    sku: '8-gen2'
    version: 'latest'
  }
  AlmaLinux_9_Gen1: {
    publisher: 'almalinux'
    offer: 'almalinux-x86_64'
    sku: '9-gen1'
    version: 'latest'
  }
  AlmaLinux_9_Gen2: {
    publisher: 'almalinux'
    offer: 'almalinux-x86_64'
    sku: '9-gen2'
    version: 'latest'
  }
  AlmaLinux_8_HPC_Gen1: {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8-hpc-gen1'
    version: 'latest'
  }
  AlmaLinux_8_HPC_Gen2: {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8-hpc-gen2'
    version: 'latest'
  }
  Rocky_Linux_8_base: {
    publisher: 'resf'
    offer: 'rockylinux-x86_64'
    sku: '8-base'
    version: 'latest'
  }
  Rocky_Linux_8_LVM: {
    publisher: 'resf'
    offer: 'rockylinux-x86_64'
    sku: '8-lvm'
    version: 'latest'
  }
  Rocky_Linux_9_base: {
    publisher: 'resf'
    offer: 'rockylinux-x86_64'
    sku: '9-base'
    version: 'latest'
  }
  Rocky_Linux_9_LVM: {
    publisher: 'resf'
    offer: 'rockylinux-x86_64'
    sku: '9-lvm'
    version: 'latest'
  }
  'CentOS_7.6': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7.6'
    version: 'latest'
  }
  'CentOS_7.7': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7.7'
    version: 'latest'
  }
  'CentOS_7.8': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_8'
    version: 'latest'
  }
  'CentOS_7.9': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_9'
    version: 'latest'
  }
  'CentOS_7.6_HPC': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7.6'
    version: 'latest'
  }
  'CentOS_7.7_HPC': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7.7'
    version: 'latest'
  }
  'CentOS_7.8_HPC': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_8'
    version: 'latest'
  }
  'CentOS_7.9_HPC': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_9'
    version: 'latest'
  }
  'CentOS_7.6_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_6-gen2'
    version: 'latest'
  }
  'CentOS_7.7_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_7-gen2'
    version: 'latest'
  }
  'CentOS_7.8_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_8-gen2'
    version: 'latest'
  }
  'CentOS_7.9_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_9-gen2'
    version: 'latest'
  }
  'CentOS_7.6_HPC_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_6gen2'
    version: 'latest'
  }
  'CentOS_7.7_HPC_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_7-gen2'
    version: 'latest'
  }
  'CentOS_7.8_HPC_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_8-gen2'
    version: 'latest'
  }
  'CentOS_7.9_HPC_Gen2': {
    publisher: 'OpenLogic'
    offer: 'CentOS-HPC'
    sku: '7_9-gen2'
    version: 'latest'
  }
  'RHEL_7.7': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '7.7'
    version: 'latest'
  }
  'RHEL_7.8': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '7.8'
    version: 'latest'
  }
  'RHEL_7.9': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '7_9'
    version: 'latest'
  }
  'RHEL_8.5': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '8_5'
    version: 'latest'
  }
  'RHEL_8.6': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '8_6'
    version: 'latest'
  }
  'RHEL_8.7': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '8_7'
    version: 'latest'
  }
  'RHEL_8.8': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '8_8'
    version: 'latest'
  }
  'RHEL_8.9': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '8_9'
    version: 'latest'
  }
  'RHEL_9.0': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '9_0'
    version: 'latest'
  }
  'RHEL_9.1': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '9_1'
    version: 'latest'
  }
  'RHEL_9.2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '9_2'
    version: 'latest'
  }
  'RHEL_9.3': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '9_3'
    version: 'latest'
  }
  'RHEL_9.4': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '9_4'
    version: 'latest'
  }
  'RHEL_9.5': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '9_5'
    version: 'latest'
  }
  'RHEL_7.7_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '77-gen2'
    version: 'latest'
  }
  'RHEL_7.8_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '78-gen2'
    version: 'latest'
  }
  'RHEL_7.9_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '79-gen2'
    version: 'latest'
  }
  'RHEL_8.5_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '85-gen2'
    version: 'latest'
  }
  'RHEL_8.6_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '86-gen2'
    version: 'latest'
  }
  'RHEL_8.7_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '87-gen2'
    version: 'latest'
  }
  'RHEL_8.8_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '88-gen2'
    version: 'latest'
  }
  'RHEL_9.0_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '90-gen2'
    version: 'latest'
  }
  'RHEL_9.1_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '91-gen2'
    version: 'latest'
  }
  'RHEL_9.2_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '92-gen2'
    version: 'latest'
  }
  'RHEL_9.3_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '93-gen2'
    version: 'latest'
  }
  'RHEL_9.4_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '94_gen2'
    version: 'latest'
  }
  'RHEL_9.5_Gen2': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '95_gen2'
    version: 'latest'
  }
  SLES_12_SP5: {
    publisher: 'SUSE'
    offer: 'sles-12-sp5'
    sku: 'gen1'
    version: 'latest'
  }
  SLES_12_SP5_HPC: {
    publisher: 'SUSE'
    offer: 'sles-12-sp5-hpc'
    sku: 'gen1'
    version: 'latest'
  }
  SLES_12_SP5_Gen2: {
    publisher: 'SUSE'
    offer: 'sles-12-sp5'
    sku: 'gen2'
    version: 'latest'
  }
  SLES_12_SP5_HPC_Gen2: {
    publisher: 'SUSE'
    offer: 'sles-12-sp5-hpc'
    sku: 'gen2'
    version: 'latest'
  }
  SLES_15_SP3_HPC: {
    publisher: 'SUSE'
    offer: 'sles-15-sp3-hpc'
    sku: 'gen1'
    version: 'latest'
  }
  'Ubuntu_16.04': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '16.04-LTS'
    version: 'latest'
  }
  'Ubuntu_18.04': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18.04-LTS'
    version: 'latest'
  }
  'Ubuntu_20.04': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts'
    version: 'latest'
  }
  'Ubuntu_22.04': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts'
    version: 'latest'
  }
  'Ubuntu_24.04': {
    publisher: 'Canonical'
    offer: 'ubuntu-24_04-lts'
    sku: 'server-gen1'
    version: 'latest'
  }
  'Ubuntu_16.04_Gen2': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '16_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu_18.04_Gen2': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu_20.04_Gen2': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu_22.04_Gen2': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu_24.04_Gen2': {
    publisher: 'Canonical'
    offer: 'ubuntu-24_04-lts'
    sku: 'server'
    version: 'latest'
  }
  'Ubuntu_18.04_HPC_Gen2': {
    publisher: 'Microsoft-DSVM'
    offer: 'Ubuntu-HPC'
    sku: '1804'
    version: 'latest'
  }
  'Ubuntu_20.04_HPC_Gen2': {
    publisher: 'Microsoft-DSVM'
    offer: 'Ubuntu-HPC'
    sku: '2004'
    version: 'latest'
  }
  'Ubuntu_22.04_HPC_Gen2': {
    publisher: 'Microsoft-DSVM'
    offer: 'Ubuntu-HPC'
    sku: '2204'
    version: 'latest'
  }
  CustomImage: {}
}

//NOTE: The properties are set as VM Tags, and the names are referenced in HPC Pack code.
//So be cautious when you want to change these names!
@export()
type AzureMonitorLogSettings = {
  LA_MiResId: string
  LA_MiClientId: string
  LA_DcrId: string
  LA_DcrStream: string
  LA_DceUrl: string
}

@export()
type AzureMonitorAgentSettings = {
  userMiResId: string
  dcrResId: string
}

@export()
type AzureSqlDataBaseServiceTier =
  | 'Standard_S0'
  | 'Standard_S1'
  | 'Standard_S2'
  | 'Standard_S3'
  | 'Standard_S4'
  | 'Standard_S6'
  | 'Standard_S7'
  | 'Standard_S9'
  | 'Standard_S12'
  | 'Premium_P1'
  | 'Premium_P2'
  | 'Premium_P3'
  | 'Premium_P4'
  | 'Premium_P6'
  | 'Premium_P11'
  | 'Premium_P15'
//End of AzureSqlDataBaseServiceTier

@export()
type AzureSqlDatabaseSettings = {
  name: string
  maxSizeBytes: int
  serviceTier: AzureSqlDataBaseServiceTier
}

@export()
type CertificateSettings = {
  vaultResourceGroup: string
  vaultName: string
  url: string
  thumbprint: string
}

@export()
func isValidCertificateSettings(certSettings CertificateSettings) bool =>
  !empty(certSettings.vaultResourceGroup) && !empty(certSettings.vaultName) && !empty(certSettings.url) && !empty(certSettings.thumbprint)

var certificateSettingsToTagsKeyMap = {
  vaultResourceGroup: 'KV_RG'
  vaultName: 'KV_Name'
  url: 'KV_CertUrl'
  thumbprint: 'KV_CertThumbprint'
}

var tagsToCertificateSettingsKeyMap = toObject(items(certificateSettingsToTagsKeyMap), obj => obj.value, obj => obj.key)

var defaultCertificateSettings = {
  vaultResourceGroup: ''
  vaultName: ''
  url: ''
  thumbprint: ''
}

@export()
func certSettingsToVmTags(certSettings CertificateSettings) object =>
  toObject(
    items(certSettings),
    obj => certificateSettingsToTagsKeyMap[obj.key],
    obj => obj.value)

@export()
func vmTagsToCertSettings(tags object) CertificateSettings =>
  union(
    defaultCertificateSettings,
    toObject(
      filter(items(tags), item => contains(tagsToCertificateSettingsKeyMap, item.key)),
      obj => tagsToCertificateSettingsKeyMap[obj.key],
      obj => obj.value))

@export()
func certSecretForWindows(vaultRg string, vaultName string, certificateUrl string) object =>
  {
    sourceVault: {
      id: resourceId(vaultRg, 'Microsoft.KeyVault/vaults', vaultName)
    }
    vaultCertificates: [
      {
        certificateUrl: certificateUrl
        certificateStore: 'My'
      }
    ]
  }

@export()
func certSecretForLinux(vaultRg string, vaultName string, certificateUrl string) object =>
  {
    sourceVault: {
      id: resourceId(vaultRg, 'Microsoft.KeyVault/vaults', vaultName)
    }
    vaultCertificates: [
      {
        certificateUrl: certificateUrl
      }
    ]
  }

var rdmaASeries = [
  'Standard_A8'
  'Standard_A9'
]

@export()
func isRDMACapable(vmSize string) bool =>
  (contains(rdmaASeries, vmSize) || contains(toLower(split(vmSize, '_')[1]), 'r'))
