#
# xHpcPackInstall: DSC resource to install HPC Pack 2019 head node.
#

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [string] $ClusterName,

        [parameter(Mandatory = $true)]
        [string] $SetupPkgPath,

        [parameter(Mandatory = $true)]
        [string] $SSLThumbprint,

        [parameter(Mandatory = $false)]
        [string] $HeadNodeList = "",        

        [parameter(Mandatory = $false)]
        [string] $SQLServerInstance = "",

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $SQLCredential,

        [parameter(Mandatory = $false)]
        [Boolean] $LinuxCommOverHttp = $false,

        [parameter(Mandatory = $false)]
        [string] $LinuxAuthenticationKey = "",

        [Parameter(Mandatory=$false)]
        [Boolean] $EnableBuiltinHA = $false
    )

    return $PSBoundParameters
}

function Set-TargetResource
{
    param
    (
        [parameter(Mandatory = $true)]
        [string] $ClusterName,

        [parameter(Mandatory = $true)]
        [string] $SetupPkgPath,

        [parameter(Mandatory = $true)]
        [string] $SSLThumbprint,

        [parameter(Mandatory = $false)]
        [string] $HeadNodeList = "",        

        [parameter(Mandatory = $false)]
        [string] $SQLServerInstance = "",

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $SQLCredential,

        [parameter(Mandatory = $false)]
        [Boolean] $LinuxCommOverHttp = $false,

        [Parameter(Mandatory=$false)]
        [Boolean] $EnableBuiltinHA = $false
    )

    $downloader = New-Object System.Net.WebClient
    # Download the setup package if it is an http/https url
    if($SetupPkgPath -match "^https?://")
    {
        $setupPkgUrl = $SetupPkgPath
        $SetupPkgPath = Join-Path "$env:windir\Temp" $($setupPkgUrl -split '/')[-1]
        DownloadFile -Downloader $downloader -SourceUrl $setupPkgUrl -DestPath $SetupPkgPath
    }

    if((Test-Path -Path $SetupPkgPath -PathType Leaf) -and [IO.Path]::GetExtension($SetupPkgPath) -eq ".zip")
    {
        $basetgtdir = $SetupPkgPath.Substring(0, $SetupPkgPath.LastIndexOf('.')) + '_HPC'
        $tgtdir = $basetgtdir
        $index = 0
        while(Test-Path -Path $tgtdir -PathType Container)
        {
            try
            {
                Remove-Item -Path $tgtdir -Recurse -Force -ErrorAction Stop
                break
            }
            catch
            {
                $tgtdir = "$basetgtdir" + "_$index"
            }
        }

        [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
        [System.IO.Compression.ZipFile]::ExtractToDirectory($SetupPkgPath, $tgtdir) | Out-Null
    }
    else
    {
        $tgtdir = $SetupPkgPath
    }

    $pfxCert = Get-Item Cert:\LocalMachine\My\$SSLThumbprint -ErrorAction SilentlyContinue
    if($null -eq $pfxCert)
    {
        throw "The certificate with thumbprint '$SSLThumbprint' doesn't exist under Cert:\LocalMachine\My"
    }

    if($pfxCert.Subject -eq $pfxCert.Issuer)
    {
        if(-not (Test-Path Cert:\LocalMachine\Root\$SSLThumbprint))
        {
            Write-Verbose "Installing certificate to Cert:\LocalMachine\Root"
            $cerFileName = "$env:Temp\HpcPackComm.cer"
            Export-Certificate -Cert "Cert:\LocalMachine\My\$SSLThumbprint" -FilePath $cerFileName | Out-Null
            Import-Certificate -FilePath $cerFileName -CertStoreLocation Cert:\LocalMachine\Root  | Out-Null
            Remove-Item $cerFileName -Force -ErrorAction SilentlyContinue
        }
    }

    $legacyHa = $false
    $setupArg = "-unattend -Quiet -HeadNode -ClusterName:$ClusterName -SSLThumbprint:$SSLThumbprint -SkipComponent:rras,dhcp,wds"
    if($LinuxCommOverHttp)
    {
        $setupArg += " -LinuxCommOverHttp"
    }
    if($LinuxAuthenticationKey)
    {
        $setupArg += " -LinuxAuthenticationKey:$LinuxAuthenticationKey"
    }
    if(!$EnableBuiltinHA -and $HeadNodeList -and ($HeadNodeList -ne $env:COMPUTERNAME))
    {
        $legacyHa = $true
        $setupArg += " -HeadNodeList:`"$HeadNodeList`""
    }
    if($SQLServerInstance)
    {
        if($PSBoundParameters.ContainsKey('SQLCredential'))
        {
            $secinfo = "Integrated Security=False;User ID={0};Password={1}" -f $SQLCredential.UserName, $SQLCredential.GetNetworkCredential().Password
        }
        else
        {
            $secinfo = "Integrated Security=True"
        }

        $mgmtConstr = "Data Source=$SQLServerInstance;Initial Catalog=HpcManagement;$secinfo"
        $schdConstr = "Data Source=$SQLServerInstance;Initial Catalog=HpcScheduler;$secinfo"
        $monConstr  = "Data Source=$SQLServerInstance;Initial Catalog=HPCMonitoring;$secinfo"
        $rptConstr  = "Data Source=$SQLServerInstance;Initial Catalog=HPCReporting;$secinfo"
        $diagConstr = "Data Source=$SQLServerInstance;Initial Catalog=HPCDiagnostics;$secinfo"
        $setupArg += " -MgmtDbConStr:`"$mgmtConstr`" -SchdDbConStr:`"$schdConstr`" -RptDbConStr:`"$rptConstr`" -DiagDbConStr:`"$diagConstr`" -MonDbConStr:`"$monConstr`""
        if(-not $legacyHa)
        {
            $haStorageConstr  = "Data Source=$SQLServerInstance;Initial Catalog=HPCHAStorage;$secinfo"
            $haWitnessConstr = "Data Source=$SQLServerInstance;Initial Catalog=HPCHAWitness;$secinfo"
            $setupArg += " -HAStorageDbConStr:`"$haStorageConstr`" -HAWitnessDbConStr:`"$haWitnessConstr`""  
        }
    }

    if($EnableBuiltinHA)
    {
        $setupVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$tgtdir\setup.exe")
        if($setupVersion.ProductVersionRaw -gt "6.0.7150.0")
        {
            $setupArg += " -EnableBuiltinHA"  
        }
    }

    $retry = 0
    $maxRetryTimes = 20
    $maxRetryInterval = 60
    while($true)
    {
        Write-Verbose "Installing HPC Pack Head Node"
        $p = Start-Process -FilePath "$tgtdir\setup.exe" -ArgumentList $setupArg -PassThru -Wait
        if($p.ExitCode -eq 0)
        {
            Write-Verbose "Succeed to Install HPC Pack Head Node"
            break
        }
        if($p.ExitCode -eq 3010)
        {
            Write-Verbose "Succeed to Install HPC Pack Head Node, a reboot is required."
            $global:DSCMachineStatus = 1
            break
        }

        if($retry++ -lt $maxRetryTimes)
        {
            $retryInterval = [System.Math]::Min($maxRetryInterval, $retry * 10)
            Write-Warning "Failed to Install HPC Pack Head Node (errCode=$($p.ExitCode)), retry after $retryInterval seconds..."            
            Clear-DnsClientCache
            Start-Sleep -Seconds $retryInterval
        }
        else
        {
            if($p.ExitCode -eq 13818)
            {
                throw "Failed to Install HPC Pack Head Node (errCode=$($p.ExitCode)): the certificate doesn't meet the requirements."
            }
            else
            {
                throw "Failed to Install HPC Pack Head Node (errCode=$($p.ExitCode))"
            }
        }
    }
}

function Test-TargetResource
{
    param
    (
        [parameter(Mandatory = $true)]
        [string] $ClusterName,

        [parameter(Mandatory = $true)]
        [string] $SetupPkgPath,

        [parameter(Mandatory = $true)]
        [string] $SSLThumbprint,

        [parameter(Mandatory = $false)]
        [string] $HeadNodeList = "",        

        [parameter(Mandatory = $false)]
        [string] $SQLServerInstance = "",

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $SQLCredential,

        [parameter(Mandatory = $false)]
        [Boolean] $LinuxCommOverHttp = $false,

        [Parameter(Mandatory=$false)]
        [Boolean] $EnableBuiltinHA = $false
    )
    
    $serverGuid = "A001F5CA-5D6A-4BDA-9885-36E7A8EBABCC"
    if($null -eq (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{$_.UninstallString -and $_.UninstallString -match $serverGuid}))
    {
        return $false
    }

    if($HeadNodeList -and ($HeadNodeList -ne $env:COMPUTERNAME))
    {
        $fabricSvc = Get-Service -Name 'fabricHostSvc' -ErrorAction SilentlyContinue
        return ($null -ne $fabricSvc)
    }
    else 
    {
        $schedulerSvc = Get-Service -Name 'HpcScheduler' -ErrorAction SilentlyContinue
        return ($null -ne $schedulerSvc)        
    }
}

function DownloadFile
{
    param(
        [parameter(Mandatory = $false)]
        [System.Net.WebClient] $Downloader = $null,

        [parameter(Mandatory = $true)]
        [string] $SourceUrl,

        [parameter(Mandatory = $true)]
        [string] $DestPath
    )

    if($Downloader -eq $null)
    {
        $Downloader = New-Object System.Net.WebClient
    }

    $fileName = $($SourceUrl -split '/')[-1]
    if(Test-Path -Path $DestPath -PathType Container)
    {
        $DestPath = [IO.Path]::Combine($DestPath, $fileName)
    }

    $downloadRetry = 0
    while($true)
    {
        try
        {
            if(Test-Path -Path $DestPath)
            {
                Remove-Item -Path $DestPath -Force -Confirm:$false -ErrorAction SilentlyContinue
            }

            Write-Verbose "Downloading $SourceUrl to $DestPath(Retry=$downloadRetry)."
            $Downloader.DownloadFile($SourceUrl, $DestPath)
            Write-Verbose "Downloaded $SourceUrl to $DestPath."
            break
        }
        catch
        {
            if($downloadRetry -lt 10)
            {
                Write-Verbose ("Failed to download files, retry after 20 seconds:" + $_)
                Clear-DnsClientCache
                Start-Sleep -Seconds 20
                $downloadRetry++
            }
            else
            {
               throw "Failed to download files after 10 retries"
            }
        }
    }
}


Export-ModuleMember -Function *-TargetResource
