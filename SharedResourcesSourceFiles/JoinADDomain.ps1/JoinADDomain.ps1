configuration JoinADDomain 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [String[]]$DNSServer = @(),

        [Int]$RetryCount=30,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement,xNetworking
    $dnsServers = @($DNSServer | %{$_ -split ','} | %{$_.Trim()})
    $DomainNetBiosName = $DomainName.Split('.')[0]
    $ADUserName = "${DomainNetBiosName}\$($Admincreds.UserName)"
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    if($dnsServers.Count -gt 0)
    {
        $netWmiObj = Get-WmiObject win32_networkadapterconfiguration -filter "IPEnabled='true' AND DHCPEnabled='true'"
        if((Get-WmiObject Win32_ComputerSystem).DomainRole -eq 3)
        {
            Write-Verbose -Message "Already domain joined"
            $netWmiObj.SetDNSServerSearchOrder()
        }
        else
        {
            Write-Verbose -Message "not domain joined"
            $netWmiObj.SetDNSServerSearchOrder($dnsServers)
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

        Group AddADUserToLocalAdminGroup
        {
            GroupName = 'Administrators'   
            Ensure = 'Present'             
            MembersToInclude= $ADUserName
            Credential = $DomainCreds    
            DependsOn = "[xComputer]DomainJoin"
        }
    }
} 
