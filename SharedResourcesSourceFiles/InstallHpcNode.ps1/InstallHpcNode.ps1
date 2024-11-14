configuration InstallHpcNode 
{ 
   param 
   ( 
        [parameter(Mandatory = $true)]
        [ValidateSet("HeadNodePreReq", "ComputeNode", "BrokerNode", "PassiveHeadNode")]
        [string] $NodeType,

        [parameter(Mandatory = $true)]
        [string] $HeadNodeList,

        [parameter(Mandatory = $true)]
        [string] $SSLThumbprint,

        [string] $SetupPkgPath = 'C:\HPCPack2019',

        [System.Management.Automation.PSCredential]$SetupUserCredential,

        [Int]$RetryCount=30,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xHpcPack, xNetworking, xSystemSecurity
    $pfxCert = Get-Item Cert:\LocalMachine\My\$SSLThumbprint -ErrorAction SilentlyContinue
    $keyFullPath = [IO.Path]::Combine($env:ProgramData,"Microsoft\Crypto\RSA\MachineKeys", $pfxCert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName)

    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        if($NodeType -eq "HeadNodePreReq" -or $NodeType -eq "PassiveHeadNode")
        {
            xFirewall AllowRemoteAdminIn
            {
                Name = "remote-administration-in"
                DisplayName = "Remote administration In"
                Ensure = "Present"
                Action = "Allow"
                Direction = "Inbound"
                Protocol = "TCP"
                LocalPort = @(445)
            }
        }

        xFileSystemAccessRule certKeyAclForAdmin
        {
            Path = $keyFullPath
            Identity = "BUILTIN\Administrators"
            Rights = "FullControl"
            Ensure = "Present"
        }

        if($PSBoundParameters.ContainsKey('SetupUserCredential'))
        {
            Group AddADUserToLocalAdminGroup
            {
                GroupName = 'Administrators'   
                Ensure = 'Present'             
                MembersToInclude= $SetupUserCredential.UserName
                Credential = $SetupUserCredential    
            }

            xHpcNodeInstall InstallHpcNode
            {
                NodeType = $NodeType
                HeadNodeList = $HeadNodeList
                SetupPkgPath = $SetupPkgPath
                SSLThumbprint = $SSLThumbprint
                PsDscRunAsCredential = $SetupUserCredential
                DependsOn = "[xFileSystemAccessRule]certKeyAclForAdmin","[Group]AddADUserToLocalAdminGroup"
            }
        }
        else 
        {
            xHpcNodeInstall InstallHpcNode
            {
                NodeType = $NodeType
                HeadNodeList = $HeadNodeList
                SetupPkgPath = $SetupPkgPath
                SSLThumbprint = $SSLThumbprint
                DependsOn = "[xFileSystemAccessRule]certKeyAclForAdmin"
            }            
        }
    }
}