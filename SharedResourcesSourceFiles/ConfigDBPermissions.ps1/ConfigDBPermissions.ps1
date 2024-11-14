configuration ConfigDBPermissions 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory)]
        [String]$HeadNodeList,

        [String]$Databases = "HPCManagement,HPCScheduler,HPCReporting,HPCDiagnostics,HPCMonitoring,HPCHAStorage,HPCHAWitness",

        [String]$SQLInstanceName = "MSSQLSERVER",

        [Int]$RetryCount=20,

        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xSQLServer, xComputerManagement, xNetworking
    $DomainNetBiosName = $DomainName.Split('.')[0]
    $ADUserName = "${DomainNetBiosName}\$($Admincreds.UserName)"
    $HeadNodes = @($HeadNodeList -split ',')
    $dbNames = @($Databases -split ',')
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ($ADUserName, $Admincreds.Password)
    if($SQLInstanceName -eq "MSSQLSERVER")
    {
        $sqlService = "MSSQLSERVER"
    }
    else
    {
        $sqlService = "MSSQL`$$SQLInstanceName"
    }

    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        WindowsFeature ADPS
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }

        xWaitForADDomain DscForestWait 
        { 
            DomainName = $DomainName 
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec 
            DependsOn = "[WindowsFeature]ADPS"      
        }

        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[xWaitForADDomain]DscForestWait" 
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
            DependsOn = "[xComputer]DomainJoin"
        }

        Group AddADUserToLocalAdminGroup
        {
            GroupName = 'Administrators'   
            Ensure = 'Present'             
            MembersToInclude= $ADUserName
            Credential = $DomainCreds    
            DependsOn = "[xComputer]DomainJoin"
        }

        xSQLServerLogin AddSQLServerLoginForADUser
        {
            Ensure = "Present"
            Name = $ADUserName
            LoginType = "WindowsUser"
            SQLInstanceName = $SQLInstanceName
            DependsOn = "[xComputer]DomainJoin"
        }

        xSQLServerRoleMembership AddSysadminForADUser
        {
            Ensure = "Present"
            RoleName = "sysadmin"
            Login = $ADUserName
            SQLInstanceName = $SQLInstanceName
            DependsOn = "[xSQLServerLogin]AddSQLServerLoginForADUser"
        }

        foreach($hn in $HeadNodes)
        {
            $HNAccount = "${DomainNetBiosName}\$hn$"
            xSQLServerLogin "AddSQLServerLoginFor$hn"
            {
                Ensure = "Present"
                Name = $HNAccount
                LoginType = "WindowsUser"
                SQLInstanceName = $SQLInstanceName
            }
            foreach($dbName in $dbNames)
            {
                xSQLServerDatabaseRole "${dbName}DBOwnerFor$hn"
                {
                    Ensure = "Present"
                    Name = $HNAccount
                    Role = "db_owner"
                    Database = $dbName
                    SQLInstanceName = $SQLInstanceName
                    DependsOn = "[xSQLServerLogin]AddSQLServerLoginFor$hn"
                }
            }
        }
    }
} 

