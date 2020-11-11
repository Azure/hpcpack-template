<#
.Synopsis
    Updates the HPC communication certificate for this HPC node.

.DESCRIPTION
    This script updates the HPC communication certificate for this HPC node.

.NOTES
    This cmdlet requires that the current machine is an HPC node in an HPC Pack 2016 or later cluster.

.EXAMPLE
    Update the HPC communication certificate for this HPC node.
    PS > Update-HpcNodeCertificate.ps1 -Thumbprint 466C3A692200566BF33ED338684299E43D3C51CE
    

.EXAMPLE
    Update the HPC communication certificate for this HPC node after 10 seconds delay.
    PS > Update-HpcNodeCertificate.ps1 -Thumbprint 466C3A692200566BF33ED338684299E43D3C51CE -Delay 10

.EXAMPLE
    Install a new certificate, and schedules a task to update it as the HPC communication certificate on this node.
    PS > Update-HpcNodeCertificate.ps1 -PfxFilePath "d:\newcert.pfx" -Password "mypassword" -RunAsScheduledTask
#>
Param
(
    # The Path of the PFX format certificate file.
    [Parameter(Mandatory=$true, ParameterSetName="PfxFile")]
    [ValidateNotNullOrEmpty()]
    [String] $PfxFilePath,

    # The protection password of the PFX format certificate file.
    [Parameter(Mandatory=$false, ParameterSetName="PfxFile")]
    [String] $Password,

    # The thumbprint of the certificate which had already been installed in "Local Computer\Personal" store on this node.
    [Parameter(Mandatory=$true, ParameterSetName="Thumbprint")]
    [ValidateNotNullOrEmpty()]
    [String] $Thumbprint,

    # If specified, the delay time in seconds for the operation.
    [Parameter(Mandatory=$false)]
    [ValidateRange(0, 3600)]
    [int] $Delay = 0,

    # If specified, update the HPC communication certificate using a scheduled task.
    [Parameter(Mandatory=$false)]
    [Switch] $RunAsScheduledTask,

    # The log file path, if not specified, the log will be generated in system temp folder.
    [Parameter(Mandatory=$false)]
    [String] $LogFile
)

$curUser = [Security.Principal.WindowsIdentity]::GetCurrent();
if(-not (New-Object Security.Principal.WindowsPrincipal $curUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
{
    throw "You must run this script with administrator privileges"
}

$VerbosePreference = "Continue"
$datestr = Get-Date -Format "yyyy_MM_dd-HH_mm_ss"
if(-not $LogFile)
{
    $LogFile = "$env:windir\Temp\Update-HpcNodeCertificate-$datestr.log"
}

function WriteLog
{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [String] $Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warning","Verbose")]
        [String] $LogLevel = "Verbose"
    )
    
    $timestr = Get-Date -Format 'MM/dd/yyyy HH:mm:ss'
    $NewMessage = "$timestr - $Message"
    switch($LogLevel)
    {
        "Error"     {Write-Error   $NewMessage; break}
        "Warning"   {Write-Warning $NewMessage; break}
        "Verbose"   {Write-Verbose $NewMessage; break}
    }
       
    try
    {
        $NewMessage = "[$LogLevel]$timestr - $Message"
        Add-Content $LogFile $NewMessage -ErrorAction SilentlyContinue
    }
    catch
    {
        #Ignore the error
    }
}

try
{
    $HPCKeyPath = "HKLM:\SOFTWARE\Microsoft\HPC"
    $HPCWow6432KeyPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\HPC"
    $sslThumbprintItem = $null
    $roleItem = $null
    $keyExists = Test-Path -Path $HPCKeyPath
    if($keyExists)
    {
        $sslThumbprintItem = Get-ItemProperty -Name SSLThumbprint -LiteralPath $HPCKeyPath -ErrorAction SilentlyContinue
        $roleItem = Get-ItemProperty -Name InstalledRole -LiteralPath $HPCKeyPath -ErrorAction SilentlyContinue
        $hnListItem = Get-ItemProperty -Name ClusterConnectionString -LiteralPath $HPCKeyPath -ErrorAction SilentlyContinue
    }

    if((-not $keyExists) -or ($null -eq $sslThumbprintItem) -or ($null -eq $roleItem) -or ($null -eq $hnListItem))
    {
        throw "This computer($env:ComputerName) is not a valid HPC cluster node"
    }

    $isHeadNode = ($roleItem.InstalledRole -contains 'HN')
    $serviceFabricHN = $false
    if($isHeadNode -and $hnListItem.ClusterConnectionString.Contains(','))
    {
        # For multiple head node, we check whether it is a service fabric cluster or new HA cluster
        $hpcSecKeyItem = Get-Item -Path HKLM:\SOFTWARE\Microsoft\HPC\Security -ErrorAction SilentlyContinue
        $serviceFabricHN = ($null -eq $hpcSecKeyItem) -or ($hpcSecKeyItem.Property -notcontains "HAStorageDbConnectionString")
    }

    # Get the current HPC Pack version by HpcCommon.dll file version (major version 5 for HPC Pack 2016, 6 for HPC Pack 2019)
    $ccpHome = [Environment]::GetEnvironmentVariable("CCP_HOME", 'Machine')
    $hpcCommonDll = [IO.Path]::Combine($ccpHome, 'Bin\HpcCommon.dll')
    $versionStr = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($hpcCommonDll).FileVersion
    $hpcVersion = New-Object System.Version $versionStr

    if($PsCmdlet.ParameterSetName -eq "PfxFile")
    {
        $keyFlags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet
        if($isHeadNode)
        {
            $keyFlags = $keyFlags -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
        }        
        try
        {
            if($PSBoundParameters.ContainsKey("Password"))
            {
                $pfxcert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $PfxFilePath,$Password,$keyFlags
            }
            else
            {
                $prompt = "Input the protection password of the certificate file $PfxFilePath"
                $secPsw = Read-Host -Prompt $prompt -AsSecureString
                $pfxcert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $PfxFilePath,$secPsw,$keyFlags
                $pswBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPsw)
                $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($pswBSTR)
            }

            $Thumbprint = $pfxcert.Thumbprint
        }
        catch [System.Management.Automation.MethodInvocationException]
        {
            throw $_.Exception.InnerException
        }

        $keySpecStr = CertUtil -p "!!123abc" -v -dump "$PfxFilePath" | ?{$_ -match 'KeySpec\s*=\s*\d'} | Select -First(1)
    }
    else
    {
        $pfxcert = Get-Item "Cert:\LocalMachine\My\$Thumbprint" -ErrorAction Stop
        $keySpecStr = CertUtil -v -store My $Thumbprint | ?{$_ -match '^\s*KeySpec\s*=\s*\d'} | Select -First(1)
    }

    WriteLog "The current Cluster communication certificate: $($sslThumbprintItem.SSLThumbPrint)" -LogLevel Verbose
    if($sslThumbprintItem.SSLThumbPrint -eq $Thumbprint)
    {
        WriteLog "This HPC node ($env:ComputerName) already uses the certificate $Thumbprint as HPC communication certificate" -LogLevel Warning
        return
    }

    if(-not $pfxcert.HasPrivateKey)
    {
        WriteLog "This certificate has no private key" -LogLevel Error
        return
    }

    $keySpecVal = -1
    if($keySpecStr)
    {
        $keySpecVal = [int]$keySpecStr.Split('=')[1].Trim().SubString(0, 1)
        if($keySpecVal -eq 2)
        {
            WriteLog "This certificate is not qualified: the KeySpec value is AT_SIGNATURE (not AT_KEYEXCHANGE)" -LogLevel Error
            return           
        }
        elseif($keySpecVal -eq 0 -and ($hpcVersion.Major -eq 5 -or $serviceFabricHN))
        {
            WriteLog "This certificate is not qualified: CNG certificate is not supported in your cluster" -LogLevel Error
            return
        }
    }

    # If run as scheduled task, the delay will be applied in the scheduled task.
    if(!$RunAsScheduledTask.IsPresent -and ($Delay -gt 0))
    {
        WriteLog "HPC communication certificate will be updated after $Delay seconds" -LogLevel Verbose
        Start-Sleep -Seconds $Delay
    }

    if($PsCmdlet.ParameterSetName -eq "PfxFile")
    {
        if(Test-Path -Path "Cert:\LocalMachine\My\$Thumbprint")
        {
            WriteLog "Cert:\LocalMachine\My\$Thumbprint already exists, remove it first"
            # If the certificate already exists in the store, we always remove it and re-import
            Remove-Item -Path "Cert:\LocalMachine\My\$Thumbprint" -Force -ErrorAction SilentlyContinue
        }
        WriteLog "Importing certificate to Cert:\LocalMachine\My\$Thumbprint"
        # We always try to change the CSP to "Microsoft Enhanced RSA and AES Cryptographic Provider"
        if($isHeadNode)
        {
            certutil.exe -f -p "$Password" -csp "Microsoft Enhanced RSA and AES Cryptographic Provider" -importpfx My "$PfxFilePath" AT_KEYEXCHANGE
        }
        else
        {
            certutil.exe -f -p "$Password" -csp "Microsoft Enhanced RSA and AES Cryptographic Provider" -importpfx My "$PfxFilePath" AT_KEYEXCHANGE,NoExport
        }
        if(-not $?)
        {
            $myStore = New-Object System.Security.Cryptography.x509Certificates.x509Store("My","LocalMachine")
            try
            {
                $myStore.Open("ReadWrite")
                $myStore.Add($pfxcert)
            }
            finally
            {
                # Close doesn't throw even when Open not successfully called
                $myStore.Close()
            }
        }
    }

    if(($pfxcert.Subject -eq $pfxcert.Issuer) -and !(Test-Path -Path "Cert:\LocalMachine\Root\$Thumbprint"))
    {
        # If the certificate is self-signed, need to install in Trusted Root CA store as well
        WriteLog "Importing certificate to Cert:\LocalMachine\Root\$Thumbprint"
        $publicCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $publicCert.Import($pfxcert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
        $rootStore = New-Object System.Security.Cryptography.x509Certificates.x509Store("Root","LocalMachine")
        try
        {
            $rootStore.Open("ReadWrite")
            $rootStore.Add($publicCert)
        }
        finally
        {
            # Close doesn't throw even when Open not successfully called
            $rootStore.Close()
        }
    }

    if($serviceFabricHN)
    {
        # set network service access to the private key
        $keyContainerName = (Get-Item -Path Cert:\LocalMachine\My\$Thumbprint).PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
        $networkServiceSid = [System.Security.Principal.WellKnownSidType]'NetworkServiceSid'
        $sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $networkServiceSid,$null
        $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $sid,"FullControl","Allow"
        $keyFullPath = Join-Path -Path $env:ProgramData -ChildPath "\Microsoft\Crypto\RSA\MachineKeys\$keyContainerName"
        # Get the current ACL of the private key
        $acl = (Get-Item $keyFullPath).GetAccessControl('Access')    
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $keyFullPath -AclObject $acl -ErrorAction Stop
    }

    if($RunAsScheduledTask.IsPresent)
    {
        # Schedule a task to run this script itself, start the scheduled task immediately and return.
        $selfFullPath = $MyInvocation.MyCommand.Definition
        WriteLog "The full path of this script is $selfFullPath" -LogLevel Verbose
        # Because ScheduledTasks PowerShell module not available in Windows Server 2008 R2,
        # We use ComObject Schedule.Service to schedule task
        # If run as scheduled task, the minimum delay time is 5 seconds
        if($Delay -lt 5)
        {
            $Delay = 5
        }
        WriteLog "Scheduling task to update HPC communication certificate $Thumbprint to with a delay of $Delay seconds" -LogLevel Verbose
        $randNum = Get-Random -Maximum 100 -Minimum 1
        $taskName = "UpdateHpcCommCert_$randNum"
        $schdService = new-object -ComObject "Schedule.Service"
        $schdService.Connect("localhost")
        $rootFolder = $schdService.GetFolder("\")
        $taskDefinition = $schdService.NewTask(0)
        $setAction = $taskDefinition.Actions.Create(0)
        $setAction.Path = "PowerShell.exe"
        $setClusNameCmd = ". '$selfFullPath' -Thumbprint $Thumbprint -Delay $Delay -LogFile '$LogFile'"
        $setAction.Arguments = '-ExecutionPolicy ByPass -Command "{0}"' -f $setClusNameCmd
        $removeAction = $taskDefinition.Actions.Create(0)
        $removeAction.Path = "SchTasks.exe"
        $removeAction.Arguments = "/Delete /TN $taskName /F"
        $setClusterTask = $Rootfolder.RegisterTaskDefinition($taskName, $taskDefinition, 2, "system", $null, 5)
        try
        {
            $setClusterTask.Run($null) | Out-Null
        }
        catch
        {
            $Rootfolder.DeleteTask($taskName, 0) | Out-Null
            throw
        }

        WriteLog "The task starts to run to update the HPC communication certificate" -LogLevel Verbose
        return
    }

    WriteLog "The current Installed HPC Role(s): $($roleItem.InstalledRole)" -LogLevel Verbose

    WriteLog "Updating the HPC communication certificate in Registry Table on $env:ComputerName" -LogLevel Verbose
    if($isHeadNode -and ($hpcVersion.Major -eq 6) -and !$hnListItem.ClusterConnectionString.Contains(','))
    {
        # For single HPC Pack 2019 head node, set cluster registry as well
        Set-HpcClusterRegistry -PropertyName SSLThumbprint -PropertyValue $Thumbprint
    }
    Set-ItemProperty -Path $HPCKeyPath -Name SSLThumbprint -Value $Thumbprint
    if(Test-Path $HPCWow6432KeyPath)
    {
        Set-ItemProperty -Path $HPCWow6432KeyPath -Name SSLThumbprint -Value $Thumbprint
    }

    $hpcServices = @("HpcManagement","HpcBroker", "HpcDeployment","HpcDiagnostics","HpcFrontendService",
       "HpcMonitoringClient","HpcMonitoringServer","HpcNamingService","HpcNodeManager","HpcReporting","HpcScheduler",
       "HpcSession","HpcSoaDiagMon","HpcWebService")

    # Check the existence of the HPC Services and restart them
    $restartFailure = $false
    foreach($svcname in $hpcServices)
    {
        $service = Get-Service -Name $svcname -ErrorAction SilentlyContinue
        if($null -eq $service)
        {
            continue
        }

        if(($service.StartType -eq [ServiceProcess.ServiceStartMode]::Automatic) -or ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::Running))
        {
            WriteLog "Restarting service: $svcname" -LogLevel Verbose
            Restart-Service -Name $svcname -Force
            if(-not $?)
            {
                $restartFailure = $true
                WriteLog ("Failed to restart HPC service: $svcname : " + $Error[0]) -LogLevel Warning
            }
        }
    }

    if(-not $restartFailure)
    {
        WriteLog "Successfully updated HPC communication certificate to $Thumbprint" -LogLevel Verbose
    }
    else
    {
        Write-Warning "One or more HPC services fail to restart, you can try to manually restart them or reboot the machine."
    }
}
catch
{
    WriteLog "Failed to update HPC communication certificate to $Thumbprint : $_" -LogLevel Error
    throw
}
