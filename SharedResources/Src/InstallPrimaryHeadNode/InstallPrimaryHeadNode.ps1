configuration InstallPrimaryHeadNode 
{ 
   param 
   ( 
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$SetupUserCredential,

        [parameter(Mandatory = $true)]
        [string] $SSLThumbprint,

        [string] $SetupPkgPath = 'C:\HPCPack2019',

        [parameter(Mandatory = $true)]
        [string] $ClusterName,

        [parameter(Mandatory = $false)]
        [string] $SQLServerInstance = "",

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$SqlLoginCredential,

        [Parameter(Mandatory=$false)]
        [Boolean] $LinuxCommOverHttp = $false,

        [Parameter(Mandatory=$false)]
        # 2019 Update 2 and below needs manual fix-up post-install by running Update-HpcLinuxAuthenticationKey.ps1
        [string] $LinuxAuthenticationKey = "",

        [Parameter(Mandatory=$false)]
        [Boolean] $EnableBuiltinHA = $false,

        [Parameter(Mandatory=$false)]
        [String] $AzureStorageConnString = "",

        [Parameter(Mandatory=$false)]
        [String] $CNSize = "",

        [Parameter(Mandatory=$false)]
        [String] $SubscriptionId = "",

        [Parameter(Mandatory=$false)]
        [String] $Location = "",
    
        [Parameter(Mandatory=$false)]
        [String] $VNet = "",

        [Parameter(Mandatory=$false)]
        [String] $Subnet = "",

        [Parameter(Mandatory=$false)]
        [String] $ResourceGroup = "",

        [Parameter(Mandatory=$false)]
        [String] $VaultResourceGroup = "",

        [Parameter(Mandatory=$false)]
        [String] $CertificateUrl = "",

        [Parameter(Mandatory=$false)]
        [String] $CNNamePrefix = "",

        [Parameter(Mandatory=$false)]
        [Boolean] $AutoGSUseManagedIdentity = $false,

        [Parameter(Mandatory=$false)]
        [String] $AutoGSApplicationId = "",

        [Parameter(Mandatory=$false)]
        [String] $AutoGSTenantId = "",

        [Parameter(Mandatory=$false)]
        [String] $AutoGSThumbprint = ""
    ) 
    
    Import-DscResource -ModuleName xHpcPack, xSystemSecurity, xPSDesiredStateConfiguration
    $pfxCert = Get-Item Cert:\LocalMachine\My\$SSLThumbprint -ErrorAction SilentlyContinue
    $keyFullPath = [IO.Path]::Combine($env:ProgramData,"Microsoft\Crypto\RSA\MachineKeys", $pfxCert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName)
    $integratedDBSec = !$PSBoundParameters.ContainsKey('SqlLoginCredential')
    $defaultLocalDB = $false
    if(-not $SQLServerInstance -or $SQLServerInstance -eq ".\ComputeCluster" -or $SQLServerInstance -eq "$env:COMPUTERNAME\ComputeCluster")
    {
        $defaultLocalSqlService = Get-Service -Name 'MSSQL$COMPUTECLUSTER' -ErrorAction SilentlyContinue
        if($defaultLocalSqlService)
        {
            $defaultLocalDB = $true
        }
    }

    if(-not $CNNamePrefix)
    {
        if($ClusterName.Length > 12)
        {
            $CNNamePrefix = $ClusterName.Substring(0, 12)
        }
        else
        {
            $CNNamePrefix = $ClusterName
        }
    }

    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        Group AddADUserToLocalAdminGroup
        {
            GroupName = 'Administrators'   
            Ensure = 'Present'             
            MembersToInclude= $SetupUserCredential.UserName
            Credential = $SetupUserCredential    
        }

        if($defaultLocalDB)
        {
            xService StartSQLBrowser
            {
                Name = "SQLBrowser"
                StartupType = "Automatic"
                State = "Running"
                StartupTimeout = 60000
            }

            xService StartSQLServer
            {
                Name = 'MSSQL$COMPUTECLUSTER'
                StartupType = "Automatic"
                State = "Running"
                StartupTimeout = 120000
            }

            xService StartSQLTELEMETRY
            {
                Name = 'SQLTELEMETRY$COMPUTECLUSTER'
                StartupType = "Automatic"
                State = "Running"
                StartupTimeout = 60000
            }

            xFileSystemAccessRule certKeyAclForAdmin
            {
                Path = $keyFullPath
                Identity = "BUILTIN\Administrators"
                Rights = "FullControl"
                Ensure = "Present"
                DependsOn = "[xService]StartSQLBrowser","[xService]StartSQLServer","[xService]StartSQLTELEMETRY"
            }
        }
        else
        {
            xFileSystemAccessRule certKeyAclForAdmin
            {
                Path = $keyFullPath
                Identity = "BUILTIN\Administrators"
                Rights = "FullControl"
                Ensure = "Present"
            }
        }
        if($integratedDBSec)
        {
            xHpcHeadNodeInstall InstallHeadNode
            {
                ClusterName = $ClusterName
                SetupPkgPath = $SetupPkgPath
                SSLThumbprint = $SSLThumbprint
                SQLServerInstance = $SQLServerInstance
                LinuxCommOverHttp = $LinuxCommOverHttp
                LinuxAuthenticationKey = $LinuxAuthenticationKey
                EnableBuiltinHA = $EnableBuiltinHA
                PsDscRunAsCredential = $SetupUserCredential
                DependsOn = "[xFileSystemAccessRule]certKeyAclForAdmin","[Group]AddADUserToLocalAdminGroup"
            }
        }
        else
        {
            xHpcHeadNodeInstall InstallHeadNode
            {
                ClusterName = $ClusterName
                SetupPkgPath = $SetupPkgPath
                SSLThumbprint = $SSLThumbprint
                SQLServerInstance = $SQLServerInstance
                SQLCredential = $SqlLoginCredential
                LinuxCommOverHttp = $LinuxCommOverHttp
                LinuxAuthenticationKey = $LinuxAuthenticationKey
                EnableBuiltinHA = $EnableBuiltinHA
                PsDscRunAsCredential = $SetupUserCredential
                DependsOn = "[xFileSystemAccessRule]certKeyAclForAdmin","[Group]AddADUserToLocalAdminGroup"
            }
        }

        xHpcWaitForCluster WaitForCluster
        {
            ConnectionString = $env:COMPUTERNAME
            PsDscRunAsCredential = $SetupUserCredential
            DependsOn = "[xHpcHeadNodeInstall]InstallHeadNode"
        }

        xHpcClusterInit InitHpcCluster
        {
            Topology = "Enterprise"
            SetupCredential = $SetupUserCredential
            AzureStorageConnString = $AzureStorageConnString
            CNSize = $CNSize
            SubscriptionId = $SubscriptionId
            Location = $Location
            VNet = $VNet
            Subnet = $Subnet
            ResourceGroup = $ResourceGroup
            VaultResourceGroup = $VaultResourceGroup
            CertificateUrl = $CertificateUrl
            CertificateThumbprint = $SSLThumbprint
            CNNamePrefix = $CNNamePrefix
            AutoGSUseManagedIdentity = $AutoGSUseManagedIdentity
            AutoGSApplicationId = $AutoGSApplicationId
            AutoGSTenantId = $AutoGSTenantId
            AutoGSThumbprint = $AutoGSThumbprint
            PsDscRunAsCredential = $SetupUserCredential
            DependsOn = "[xHpcWaitForCluster]WaitForCluster"
        }
    }
}