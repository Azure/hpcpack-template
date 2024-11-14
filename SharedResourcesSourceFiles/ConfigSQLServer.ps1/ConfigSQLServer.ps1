configuration ConfigSQLServer 
{ 
   param 
   ( 
        [String]$SQLInstanceName = "MSSQLSERVER",

        [System.Management.Automation.PSCredential]$LoginCredential,

        [Int]$RetryCount=20,

        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xStorage, xSQLServer, xNetworking
    if($SQLInstanceName -eq "MSSQLSERVER")
    {
        $sqlService = "MSSQLSERVER"
    }
    else
    {
        $sqlService = "MSSQL`$$SQLInstanceName"
    }

    $isMixedMode = $PSBoundParameters.ContainsKey('LoginCredential')

    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        xWaitforDisk Disk2
        {
             DiskNumber = 2
             RetryIntervalSec =$RetryIntervalSec
             RetryCount = $RetryCount
        }

        xDisk ADDataDisk
        {
            DiskNumber = 2
            DriveLetter = "F"
            FSLabel = 'ADData'
            DependsOn = "[xWaitforDisk]Disk2"
        }

        xFirewall SQLServerTCPIn
        {
            Name = "sqlservice-tcp-in"
            DisplayName = "Allow SQL Server TCP In"
            Ensure = "Present"
            Action = "Allow"
            Direction = "Inbound"
            Protocol = "TCP"
            Service = $sqlService
        }

        File HPCDataFolder
        {
            Type = 'Directory'
            Ensure = "Present"
            DestinationPath = 'F:\HPCData'
            DependsOn = "[xDisk]ADDataDisk"
        }

        cSQLServerDatabase HPCManagementDB
        {
            Database = 'HPCManagement'
            Ensure = 'Present'
            SQLInstanceName = $SQLInstanceName
            Location = 'F:\HPCData'
            DataFileSizeInMB = 2048
            DataFileGrowthPercent = 50
            LogFileSizeInMB = 256
            LogFileGrowthPercent = 10
            DependsOn = "[File]HPCDataFolder"
        }

        cSQLServerDatabase HPCSchedulerDB
        {
            Database = 'HPCScheduler'
            Ensure = 'Present'
            SQLInstanceName = $SQLInstanceName
            Location = 'F:\HPCData'
            DataFileSizeInMB = 2048
            DataFileGrowthPercent = 50
            LogFileSizeInMB = 256
            LogFileGrowthPercent = 50
            DependsOn = "[File]HPCDataFolder"
        }

        cSQLServerDatabase HPCReportingDB
        {
            Database = 'HPCReporting'
            Ensure = 'Present'
            SQLInstanceName = $SQLInstanceName
            Location = 'F:\HPCData'
            DataFileSizeInMB = 2048
            DataFileGrowthPercent = 50
            LogFileSizeInMB = 256
            LogFileGrowthPercent = 10
            DependsOn = "[File]HPCDataFolder"
        }

        cSQLServerDatabase HPCDiagnosticsDB
        {
            Database = 'HPCDiagnostics'
            Ensure = 'Present'
            SQLInstanceName = $SQLInstanceName
            Location = 'F:\HPCData'
            DataFileSizeInMB = 256
            DataFileGrowthPercent = 50
            LogFileSizeInMB = 64
            LogFileGrowthPercent = 10
            DependsOn = "[File]HPCDataFolder"
        }

        cSQLServerDatabase HPCMonitoringDB
        {
            Database = 'HPCMonitoring'
            Ensure = 'Present'
            SQLInstanceName = $SQLInstanceName
            Location = 'F:\HPCData'
            DataFileSizeInMB = 512
            DataFileGrowthPercent = 50
            LogFileSizeInMB = 64
            LogFileGrowthPercent = 10
            DependsOn = "[File]HPCDataFolder"
        }

        cSQLServerDatabase HPCHAStorageDB
        {
            Database = 'HPCHAStorage'
            Ensure = 'Present'
            SQLInstanceName = $SQLInstanceName
            Location = 'F:\HPCData'
            DataFileSizeInMB = 128
            DataFileGrowthPercent = 50
            LogFileSizeInMB = 64
            LogFileGrowthPercent = 10
            DependsOn = "[File]HPCDataFolder"
        }
        

        cSQLServerDatabase HPCHAWitnessDB
        {
            Database = 'HPCHAWitness'
            Ensure = 'Present'
            SQLInstanceName = $SQLInstanceName
            Location = 'F:\HPCData'
            DataFileSizeInMB = 128
            DataFileGrowthPercent = 50
            LogFileSizeInMB = 64
            LogFileGrowthPercent = 10
            DependsOn = "[File]HPCDataFolder"
        }

        if($isMixedMode)
        {
            cSQLServerLoginMode SetMixedLoginMode
            {
                SQLInstanceName = $SQLInstanceName
                LoginMode = "Mixed"
                DependsOn = "[cSQLServerDatabase]HPCManagementDB","[cSQLServerDatabase]HPCSchedulerDB","[cSQLServerDatabase]HPCReportingDB","[cSQLServerDatabase]HPCDiagnosticsDB","[cSQLServerDatabase]HPCMonitoringDB","[cSQLServerDatabase]HPCHAStorageDB","[cSQLServerDatabase]HPCHAWitnessDB"
            }

            xSQLServerLogin AddSQLServerLogin
            {
                Ensure = "Present"
                Name = $LoginCredential.UserName
                LoginType = "SqlLogin"
                LoginCredential = $LoginCredential
                SQLInstanceName = $SQLInstanceName
                DependsOn = "[cSQLServerLoginMode]SetMixedLoginMode"
            }

            xSQLServerRoleMembership AddSysadminForLogin
            {
                Ensure = "Present"
                RoleName = "sysadmin"
                Login = $LoginCredential.UserName
                SQLInstanceName = $SQLInstanceName
                DependsOn = "[xSQLServerLogin]AddSQLServerLogin"
            }
        }
    }
} 

