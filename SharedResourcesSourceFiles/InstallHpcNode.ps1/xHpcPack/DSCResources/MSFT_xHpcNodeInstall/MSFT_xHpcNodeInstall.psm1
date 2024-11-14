#
# xHpcPackInstall: DSC resource to install HPC Pack.
#

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("ComputeNode", "BrokerNode", "HeadNodePreReq", "PassiveHeadNode")]
        [string] $NodeType,

        [parameter(Mandatory = $true)]
        [string] $HeadNodeList,

        [parameter(Mandatory = $true)]
        [string] $SetupPkgPath,

        [parameter(Mandatory = $true)]
        [string] $SSLThumbprint
    )

    return $PSBoundParameters
}

function Set-TargetResource
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("ComputeNode", "BrokerNode", "HeadNodePreReq", "PassiveHeadNode")]
        [string] $NodeType,

        [parameter(Mandatory = $true)]
        [string] $HeadNodeList,

        [parameter(Mandatory = $true)]
        [string] $SetupPkgPath,

        [parameter(Mandatory = $true)]
        [string] $SSLThumbprint
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
    if($pfxCert -eq $null)
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

    $setupArg = "-unattend -Quiet -${NodeType}:`"$HeadNodeList`" -SSLThumbprint:$SSLThumbprint"
    $retry = 0
    while($true)
    {
        Write-Verbose "Installing HPC $NodeType"
        $p = Start-Process -FilePath "$tgtdir\setup.exe" -ArgumentList $setupArg -PassThru -Wait
        if($p.ExitCode -eq 0)
        {
            Write-Verbose "Succeed to Install HPC $NodeType"
            break
        }
        if($p.ExitCode -eq 3010)
        {
            Write-Verbose "Succeed to Install HPC $NodeType, a reboot is required."
            $global:DSCMachineStatus = 1
            break
        }
        if($p.ExitCode -eq 13818)
        {
            throw "Failed to Install HPC $NodeType (errCode=$($p.ExitCode)): the certificate doesn't meet the requirements."
        }

        if($retry++ -lt 5)
        {
            Write-Warning "Failed to Install HPC $NodeType (errCode=$($p.ExitCode)), retry later..."
            Clear-DnsClientCache
            Start-Sleep -Seconds ($retry * 10)
        }
        else
        {
            throw "Failed to Install HPC $NodeType (ErrCode=$($p.ExitCode))"
        }
    }
}

function Test-TargetResource
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("ComputeNode", "BrokerNode", "HeadNodePreReq", "PassiveHeadNode")]
        [string] $NodeType,

        [parameter(Mandatory = $true)]
        [string] $HeadNodeList,

        [parameter(Mandatory = $true)]
        [string] $SetupPkgPath,

        [parameter(Mandatory = $true)]
        [string] $SSLThumbprint
    )
    
    $serverGuid = "02985CCE-D7D5-40FF-9C81-6334523210F9"
    if($null -eq (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{$_.UninstallString -and $_.UninstallString -match $serverGuid}))
    {
        return $false
    }

    $hpcRegKey = Get-Item HKLM:\SOFTWARE\Microsoft\HPC -ErrorAction SilentlyContinue
    if($hpcRegKey)
    {
        if($NodeType -eq 'ComputeNode')
        {
            $desiredRole = 'CN'
        }
        elseif($NodeType -eq 'BrokerNode')
        {
            $desiredRole = 'BN'
        }
        elseif($NodeType -eq 'HeadNodePreReq')
        {
            $desiredRole = 'HN'
        }

        $roles = $hpcRegKey | Get-ItemProperty | Select -Property InstalledRole
        if($roles -and ($roles.InstalledRole -contains $desiredRole))
        {
            return $true
        }
    }

    return $false
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
