#
# xHpcPackInstall: DSC resource to install HPC Pack.
#

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        # Currently only topology "Enterprise" is supported in Azure
        [Parameter(Mandatory=$true)]
        [ValidateSet("Enterprise")]
        [String] $Topology,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential] $SetupCredential,

        [Parameter(Mandatory=$false)]
        [Boolean] $LinuxCommOverHttp,

        [Parameter(Mandatory=$false)]
        [String] $AzureStorageConnString,

        [Parameter(Mandatory=$false)]
        [String] $CNSize,

        [Parameter(Mandatory=$false)]
        [String] $SubscriptionId,

        [Parameter(Mandatory=$false)]
        [String] $Location,

        [Parameter(Mandatory=$false)]
        [String] $VNet,

        [Parameter(Mandatory=$false)]
        [String] $Subnet,

        [Parameter(Mandatory=$false)]
        [String] $ResourceGroup,

        [Parameter(Mandatory=$false)]
        [String] $VaultResourceGroup,

        [Parameter(Mandatory=$false)]
        [String] $CertificateUrl,

        [Parameter(Mandatory=$false)]
        [String] $CertificateThumbprint,

        [Parameter(Mandatory=$false)]
        [String] $CNNamePrefix,

        [Parameter(Mandatory=$false)]
        [Boolean] $AutoGSUseManagedIdentity,

        [Parameter(Mandatory=$false)]
        [String] $AutoGSApplicationId,

        [Parameter(Mandatory=$false)]
        [String] $AutoGSTenantId,

        [Parameter(Mandatory=$false)]
        [String] $AutoGSThumbprint
    )

    return $PSBoundParameters
}

function Set-TargetResource
{
    param
    (
        # Currently only topology "Enterprise" is supported in Azure
        [Parameter(Mandatory=$true)]
        [ValidateSet("Enterprise")]
        [String] $Topology,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential] $SetupCredential,

        [Parameter(Mandatory=$false)]
        [Boolean] $LinuxCommOverHttp,

        [Parameter(Mandatory=$false)]
        [String] $AzureStorageConnString,

        [Parameter(Mandatory=$false)]
        [String] $CNSize,

        [Parameter(Mandatory=$false)]
        [String] $SubscriptionId,

        [Parameter(Mandatory=$false)]
        [String] $Location,

        [Parameter(Mandatory=$false)]
        [String] $VNet,

        [Parameter(Mandatory=$false)]
        [String] $Subnet,

        [Parameter(Mandatory=$false)]
        [String] $ResourceGroup,

        [Parameter(Mandatory=$false)]
        [String] $VaultResourceGroup,

        [Parameter(Mandatory=$false)]
        [String] $CertificateUrl,
        
        [Parameter(Mandatory=$false)]
        [String] $CertificateThumbprint,

        [Parameter(Mandatory=$false)]
        [String] $CNNamePrefix,

        [Parameter(Mandatory=$false)]
        [Boolean] $AutoGSUseManagedIdentity,

        [Parameter(Mandatory=$false)]
        [String] $AutoGSApplicationId,

        [Parameter(Mandatory=$false)]
        [String] $AutoGSTenantId,

        [Parameter(Mandatory=$false)]
        [String] $AutoGSThumbprint
    )

    LoadHPCPshModules
    $singleHN = $(IsSingleHeadNode)
    
    $desiredProperties = @{}
    if($PSBoundParameters.ContainsKey('SubscriptionId') -and $SubscriptionId)
    {
        $desiredProperties['SubscriptionId'] = ($SubscriptionId -as [System.Guid])
    }
    if($PSBoundParameters.ContainsKey('Location') -and $Location)
    {
        $desiredProperties['Location'] = $Location
    }
    if($PSBoundParameters.ContainsKey('VNet') -and $VNet)
    {
        $desiredProperties['VNet'] = $VNet
    }
    if($PSBoundParameters.ContainsKey('Subnet') -and $Subnet)
    {
        $desiredProperties['Subnet'] = $Subnet
    }
    if($PSBoundParameters.ContainsKey('ResourceGroup') -and $ResourceGroup)
    {
        $desiredProperties['ResourceGroup'] = $ResourceGroup
    }
    if($PSBoundParameters.ContainsKey('AutoGSApplicationId') -and $AutoGSApplicationId)
    {
        $desiredProperties['ApplicationId'] = $AutoGSApplicationId
    }
    if($PSBoundParameters.ContainsKey('AutoGSTenantId') -and $AutoGSTenantId)
    {
        $desiredProperties['TenantId'] = $AutoGSTenantId
    }
    if($PSBoundParameters.ContainsKey('AutoGSThumbprint') -and $AutoGSThumbprint)
    {
        $desiredProperties['Thumbprint'] = $AutoGSThumbprint
    }
    if($PSBoundParameters.ContainsKey('AutoGSUseManagedIdentity'))
    {
        if($AutoGSUseManagedIdentity)
        {
            $desiredProperties['UseManagedIdentity'] = 1
        }
        else
        {
            $desiredProperties['UseManagedIdentity'] = 0
        }
    }
    if($PSBoundParameters.ContainsKey('LinuxCommOverHttp'))
    {
        if($LinuxCommOverHttp)
        {
            $desiredProperties['LinuxHttps'] = 0
        }
        else
        {
            $desiredProperties['LinuxHttps'] = 1
        }
    }
    
    $retry = 0
    while($true)
    {
        try
        {
            # Get-HpcClusterRegistry will throw exception anyway if failed to connect to management service, we will retry in this case
            $curProperties = Get-HpcClusterRegistry -ErrorAction SilentlyContinue
            break
        }
        catch
        {
            if($retry++ -ge 30)
            {
                throw "Cannot get Hpc cluster registry: $($_ | Out-String)"
            }
            else
            {
                $interval = [Math]::Ceiling($retry/10) * 10
                Write-Verbose "Cannot get Hpc cluster registry, wait for $interval seconds ... $_"
                Start-Sleep -Seconds $interval
            }
        }
    }

    $retry = 0
    while($true)
    {
        try
        {
            # Get-HpcNetworkTopology will throw exception anyway if failed to connect to management service, we will retry in this case
            $topo = Get-HpcNetworkTopology -ErrorAction SilentlyContinue
            break
        }
        catch
        {
            if($retry++ -ge 30)
            {
                throw "Cannot get Hpc network toplogy: $_"
            }
            else
            {
                $interval = [Math]::Ceiling($retry/10) * 10
                Write-Verbose "Cannot get Hpc network toplogy, wait for $interval seconds ..."
                Start-Sleep -Seconds $interval
            }
        }
    }

    if($topo -ne $Topology)
    {
        $startTime = Get-Date
        Write-Verbose "Set HPC Network topology"
        $nic = Get-WmiObject win32_networkadapterconfiguration -filter "IPEnabled='true' AND DHCPEnabled='true'" | Select -First(1)
        if ($null -eq $nic)
        {
            throw "Cannot find a suitable network adapter for enterprise topology"
        }

        $retry = 0
        while($true)
        {
            try
            {
                Set-HpcNetwork -Topology $Topology -Enterprise $nic.Description -EnterpriseFirewall $true -ErrorAction Stop
                break
            }
            catch
            {
                if($retry++ -ge 20)
                {
                    throw "Failed to set HPC network topology: $($_ | Out-String)"
                }
                else
                {
                    $interval = [Math]::Ceiling($retry/10) * 10
                    Write-Verbose "Failed to set HPC network topology, maybe the cluster is not ready yet, wait for $interval seconds and retry ..."
                    Start-Sleep -Seconds $interval
                }
            }
        }
    }

    $needRestartScheduler = $false
    foreach($pName in $desiredProperties.Keys)
    {
        $curValue = $curProperties | ?{$_.Name -eq $pName} | select -First(1) | %{$_.Value}
        if($desiredProperties[$pName] -ne $curValue)
        {
            Write-Verbose "Setting cluster registry $pName to $($desiredProperties[$pName])"
            SetHpcClusterRegistry -PropertyName $pName -PropertyValue $desiredProperties[$pName]
            if($pName -eq 'LinuxHttps')
            {
                $needRestartScheduler = $true
            }
        }
    }

    $depId = ("00000000" + [System.Guid]::NewGuid().ToString().Substring(8)) -as [System.Guid]
    SetHpcClusterRegistry -PropertyName DeploymentId -PropertyValue $depId

    $retry = 0
    Write-Verbose "Setting HPC Setup User Credential"
    while($true)
    {
        try
        {
            Set-HpcClusterProperty -InstallCredential $SetupCredential -ErrorAction Stop
            break
        }
        catch
        {
            if($retry++ -ge 30)
            {
                throw "Failed to set Setup User Credential: $_"
            }
            else
            {
                $interval = [Math]::Ceiling($retry/10) * 10
                Write-Verbose "Failed to set Setup User Credential, wait for $interval seconds ..."
                Start-Sleep -Seconds $interval
            }
        }
    }

    $retry = 0
    if($PSBoundParameters.ContainsKey('CNNamePrefix') -and $CNNamePrefix)
    {
        $nodenaming = $CNNamePrefix + '%100%'
    }
    else
    {
        $nodenaming = 'AzureVMCN-%1000%'
    }
    Write-Verbose "Setting Node naming series to $nodenaming"
    while($true)
    {
        try
        {
            Set-HpcClusterProperty -NodeNamingSeries $nodenaming -ErrorAction Stop
            break
        }
        catch
        {
            if($retry++ -ge 30)
            {
                throw "Failed to set NodeNamingSeries: $_"
            }
            else
            {
                $interval = [Math]::Ceiling($retry/10) * 10
                Write-Verbose "Failed to set NodeNamingSeries, wait for $interval seconds ..."
                Start-Sleep -Seconds $interval
            }
        }
    }

    Write-Verbose "Setting AzureStorageConnectionString"
    if($PSBoundParameters.ContainsKey('AzureStorageConnString') -and $AzureStorageConnString)
    {
        try
        {
            Set-HpcClusterProperty -AzureStorageConnectionString $AzureStorageConnString -ErrorAction Stop
        }
        catch
        {
            Write-Warning "Failed to set AzureStorageConnectionString: $($_ | Out-String)"
        }
    }

    if(($PSBoundParameters.ContainsKey('VaultResourceGroup') -and $VaultResourceGroup) -and `
       ($PSBoundParameters.ContainsKey('CertificateUrl') -and $CertificateUrl) -and `
       ($PSBoundParameters.ContainsKey('CertificateThumbprint') -and $CertificateThumbprint))
    {
        try
        {
            Set-HpcKeyVaultCertificate -ResourceGroup $VaultResourceGroup -CertificateUrl $CertificateUrl -CertificateThumbprint $CertificateThumbprint -ErrorAction Stop
        }
        catch
        {
            Write-Warning "Failed to set HpcKeyVaultCertificate: $($_ | Out-String)"
        }
    }

    try
    {
        # If the VMSize of the compute nodes is A8/A9, set the MPI net mask.
        if($CNSize -match "(A8|A9)$")
        {
            Write-Verbose "The VM Size of compute nodes is $CNSize"
            $mpiNetMask = "172.16.0.0/255.255.0.0"
            ## Wait for the completion of the "Updating cluster configuration" operation after setting network topology,
            ## because in the operation, the CCP_MPI_NETMASK may be reset.
            if($topo -ne $Topology)
            {
                $waitLoop = 0
                while ($null -eq (Get-HpcOperation -StartTime $startTime -State Committed | ?{$_.Name -eq "Updating cluster configuration"}))
                {
                    if($waitLoop++ -ge 10)
                    {
                        break
                    }

                    Start-Sleep -Seconds 10
                }
            }

            Write-Verbose "Setting cluster environment CCP_MPI_NETMASK to $mpiNetMask"
            Set-HpcClusterProperty -Environment "CCP_MPI_NETMASK=$mpiNetMask"  | Out-Null
            Write-Verbose "cluster environment CCP_MPI_NETMASK was successfully set"
        }
    }
    catch
    {
        Write-Warning "Failed to set environment CCP_MPI_NETMASK: $($_ | Out-String)"
    }

    try
    {
        if($needRestartScheduler)
        {
            if($singleHN)
            {
                Write-Verbose "Restart HPC scheduler service"
                Restart-Service -Name HpcScheduler -Force -Confirm:$false -ErrorAction Stop
            }
            else
            {
                Write-Verbose "Triggering a restart of scheduler stateful service"
                $opId = [Guid]::NewGuid()
                Start-ServiceFabricPartitionRestart -OperationId $opId -RestartPartitionMode AllReplicasOrInstances -ServiceName fabric:/HpcApplication/SchedulerStatefulService -ErrorAction Stop
                Write-Verbose "A restart of scheduler stateful service was triggered"
            }
        }
    }
    catch
    {
        Write-Warning "Failed to restart HPC scheduler service: $($_ | Out-String)"
    }
}

function Test-TargetResource
{
    param
    (
        # Currently only topology "Enterprise" is supported in Azure
        [Parameter(Mandatory=$true)]
        [ValidateSet("Enterprise")]
        [String] $Topology,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential] $SetupCredential,

        [Parameter(Mandatory=$false)]
        [Boolean] $LinuxCommOverHttp,

        [Parameter(Mandatory=$false)]
        [String] $AzureStorageConnString,

        [Parameter(Mandatory=$false)]
        [String] $CNSize,

        [Parameter(Mandatory=$false)]
        [String] $SubscriptionId,

        [Parameter(Mandatory=$false)]
        [String] $Location,

        [Parameter(Mandatory=$false)]
        [String] $VNet,

        [Parameter(Mandatory=$false)]
        [String] $Subnet,

        [Parameter(Mandatory=$false)]
        [String] $ResourceGroup,

        [Parameter(Mandatory=$false)]
        [String] $VaultResourceGroup,

        [Parameter(Mandatory=$false)]
        [String] $CertificateUrl,

        [Parameter(Mandatory=$false)]
        [String] $CertificateThumbprint,

        [Parameter(Mandatory=$false)]
        [String] $CNNamePrefix,

        [Parameter(Mandatory=$false)]
        [Boolean] $AutoGSUseManagedIdentity,

        [Parameter(Mandatory=$false)]
        [String] $AutoGSApplicationId,

        [Parameter(Mandatory=$false)]
        [String] $AutoGSTenantId,

        [Parameter(Mandatory=$false)]
        [String] $AutoGSThumbprint
    )
    
    try
    {
        LoadHPCPshModules
        $topo = Get-HpcNetworkTopology -ErrorAction SilentlyContinue
        if($topo -ne $Topology)
        {
            Write-Verbose "Network topology not set"
            return $false
        }

        $hpccred = Get-HpcClusterProperty -InstallCredential -ErrorAction SilentlyContinue
        if($null -eq $hpccred)
        {
            Write-Verbose "InstallCredential need to be set"
            return $false
        }

        $cnNameSeries = Get-HpcClusterProperty -NodeNamingSeries -ErrorAction SilentlyContinue
        if($null -eq $cnNameSeries)
        {
            Write-Verbose "NodeNamingSeries need to be set"
            return $false
        }

        if($PSBoundParameters.ContainsKey('AzureStorageConnString') -and $AzureStorageConnString)
        {
            $curStorageConnString = Get-HpcClusterProperty -Name AzureStorageConnectionString -Parameter -ErrorAction SilentlyContinue
            if($AzureStorageConnString -ne $curStorageConnString)
            {
                Write-Verbose "AzureStorageConnectionString need to be set"
                return $false
            }
        }

        if(($PSBoundParameters.ContainsKey('VaultResourceGroup') -and $VaultResourceGroup) -and `
           ($PSBoundParameters.ContainsKey('CertificateUrl') -and $CertificateUrl) -and `
           ($PSBoundParameters.ContainsKey('CertificateThumbprint') -and $CertificateThumbprint))
        {
            $curKeyVault = Get-HpcKeyVaultCertificate
            $curVaultRg = $curKeyVault | ?{$_.Name -eq "ResourceGroup"} | select -First(1) | %{$_.Value}
            if($VaultResourceGroup -ne $curVaultRg)
            {
                Write-Verbose "VaultResourceGroup need to be set"
                return $false
            }
            $curVaultCertUrl = $curKeyVault | ?{$_.Name -eq "CertificateUrl"} | select -First(1) | %{$_.Value}
            if($CertificateUrl -ne $curVaultCertUrl)
            {
                Write-Verbose "CertificateUrl need to be set"
                return $false
            }
            $curVaultCertThumbprint = $curKeyVault | ?{$_.Name -eq "CertificateThumbprint"} | select -First(1) | %{$_.Value}
            if($CertificateThumbprint -ne $curVaultCertThumbprint)
            {
                Write-Verbose "CertificateThumbprint need to be set"
                return $false
            }
        }

        $desiredProperties = @{}
        if($PSBoundParameters.ContainsKey('SubscriptionId') -and $SubscriptionId)
        {
            $desiredProperties['SubscriptionId'] = ($SubscriptionId -as [System.Guid])
        }
        if($PSBoundParameters.ContainsKey('Location') -and $Location)
        {
            $desiredProperties['Location'] = $Location
        }
        if($PSBoundParameters.ContainsKey('VNet') -and $VNet)
        {
            $desiredProperties['VNet'] = $VNet
        }
        if($PSBoundParameters.ContainsKey('Subnet') -and $Subnet)
        {
            $desiredProperties['Subnet'] = $Subnet
        }
        if($PSBoundParameters.ContainsKey('ResourceGroup') -and $ResourceGroup)
        {
            $desiredProperties['ResourceGroup'] = $ResourceGroup
        }
        if($PSBoundParameters.ContainsKey('AutoGSApplicationId') -and $AutoGSApplicationId)
        {
            $desiredProperties['ApplicationId'] = $AutoGSApplicationId
        }
        if($PSBoundParameters.ContainsKey('AutoGSTenantId') -and $AutoGSTenantId)
        {
            $desiredProperties['TenantId'] = $AutoGSTenantId
        }
        if($PSBoundParameters.ContainsKey('AutoGSThumbprint') -and $AutoGSThumbprint)
        {
            $desiredProperties['Thumbprint'] = $AutoGSThumbprint
        }
        if($PSBoundParameters.ContainsKey('AutoGSUseManagedIdentity'))
        {
            if($AutoGSUseManagedIdentity)
            {
                $desiredProperties['UseManagedIdentity'] = 1
            }
            else
            {
                $desiredProperties['UseManagedIdentity'] = 0
            }
        }        
        if($PSBoundParameters.ContainsKey('LinuxCommOverHttp'))
        {
            if($LinuxCommOverHttp)
            {
                $desiredProperties['LinuxHttps'] = 0
            }
            else
            {
                $desiredProperties['LinuxHttps'] = 1
            }
        }

        $curProperties = Get-HpcClusterRegistry
        foreach($pName in $desiredProperties.Keys)
        {
            if(-not $desiredProperties[$pName])
            {
                continue
            }

            $curValue = $curProperties | ?{$_.Name -eq $pName} | select -First(1) | %{$_.Value}
            if($desiredProperties[$pName] -ne $curValue)
            {
                Write-Verbose "Property $pName need to be set"
                return $false
            }
        }

        return $true
    }
    catch
    {
        Write-Verbose "Failed to get cluster initial state: $($_ | Out-String)"
        return $false
    }
}

function LoadHPCPshModules
{
    $hpcModule = Get-Module -Name ccppsh -ErrorAction SilentlyContinue -Verbose:$false
    if($null -eq $hpcModule)
    {
        $ccpPshDll = [System.IO.Path]::Combine([System.Environment]::GetEnvironmentVariable("CCP_HOME", "Machine"), "Bin\ccppsh.dll")
        Import-Module $ccpPshDll -ErrorAction Stop -Verbose:$false | Out-Null
        $curEnvPaths = $env:Path -split ';'
        $machineEnvPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';'
        $env:Path = ($curEnvPaths + $machineEnvPath | select -Unique) -join ';'
    }
}


function SetHpcClusterRegistry
{
    param($PropertyName, $PropertyValue)

    $retry = 0
    while($true)
    {
        try
        {
            Set-HpcClusterRegistry -PropertyName $PropertyName -PropertyValue $PropertyValue -ErrorAction Stop
            Write-Verbose "Cluster registry $PropertyName successfully set to $PropertyValue"
            break
        }
        catch
        {
            if($retry++ -ge 30)
            {
                throw "Failed to set cluster registry $PropertyName : $_"
            }
            else
            {
                $interval = [Math]::Ceiling($retry/10) * 10
                Write-Verbose "Failed to set cluster registry $PropertyName, wait for $interval seconds ... $_"
                Start-Sleep -Seconds $interval
            }
        }
    }
}

function IsSingleHeadNode
{
    $clusterConnStr = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC).ClusterConnectionString
    return (($clusterConnStr -split ',').Count -eq 1)
}

Export-ModuleMember -Function *-TargetResource
