@export()
var sharedResxBaseUrl = 'https://raw.githubusercontent.com/Azure/hpcpack-template/master/HPCPack2019/shared-resources'

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
type HeadNodeImage = 'WindowsServer2022' | 'WindowsServer2019' | 'CustomImage'

@export()
var headNodeImages = {
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

@export()
type WindowsComputeNodeImage = 'WindowsServer2012' | 'WindowsServer2012R2' | 'WindowsServer2016' | 'WindowsServer2019' | 'WindowsServer2022' | 'WindowsServer2012R2WithExcel' | 'WindowsServer2016WithExcel' | 'WindowsServer2012_Gen2' | 'WindowsServer2012R2_Gen2' | 'WindowsServer2016_Gen2' | 'WindowsServer2019_Gen2' | 'WindowsServer2022_Gen2' | 'CustomImage'

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
var linuxComputeNodeImages = {
  'AlmaLinux_8.5': {
    publisher: 'almalinux'
    offer: 'almalinux'
    sku: '8_5'
    version: 'latest'
  }
  'AlmaLinux_8.5_Gen2': {
    publisher: 'almalinux'
    offer: 'almalinux'
    sku: '8_5-gen2'
    version: 'latest'
  }
  'AlmaLinux_8.5_HPC': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_5-hpc'
    version: 'latest'
  }
  'AlmaLinux_8.5_HPC_Gen2': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_5-hpc-gen2'
    version: 'latest'
  }
  'AlmaLinux_8.6_HPC': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_6-hpc'
    version: 'latest'
  }
  'AlmaLinux_8.6_HPC_Gen2': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_6-hpc-gen2'
    version: 'latest'
  }
  'AlmaLinux_8.7_HPC': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_7-hpc-gen1'
    version: 'latest'
  }
  'AlmaLinux_8.7_HPC_Gen2': {
    publisher: 'almalinux'
    offer: 'almalinux-hpc'
    sku: '8_7-hpc-gen2'
    version: 'latest'
  }
  'Rocky Linux 8.6': {
    publisher: 'erockyenterprisesoftwarefoundationinc1653071250513'
    offer: 'rockylinux'
    sku: 'free'
    version: '8.6.0'
  }
  'Rocky Linux 8.7': {
    publisher: 'erockyenterprisesoftwarefoundationinc1653071250513'
    offer: 'rockylinux'
    sku: 'free'
    version: '8.7.0'
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
}
