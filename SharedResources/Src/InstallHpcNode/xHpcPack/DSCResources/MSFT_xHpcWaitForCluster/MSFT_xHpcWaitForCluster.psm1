#
# xHpcWaitForCluster: DSC resource to wait for cluster up.
#

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $ConnectionString,

        [Parameter(Mandatory=$false)]
        [UInt64]$RetryIntervalSec = 20,

        [Parameter(Mandatory=$false)]
        [UInt32]$RetryCount = 30
    )

    return $PSBoundParameters
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $ConnectionString,

        [Parameter(Mandatory=$false)]
        [UInt64]$RetryIntervalSec = 20,

        [Parameter(Mandatory=$false)]
        [UInt32]$RetryCount = 30
    )

    AddHPCPshModules  | Out-Null
    $retry = 0
    while($true)
    {
        try
        {
            # Get-HpcNetworkTopology will throw exception anyway if failed to connect to management service, we will retry in this case
            Get-HpcClusterRegistry -Scheduler $ConnectionString -ErrorAction Stop  | Out-Null
            break
        }
        catch
        {
            if($retry++ -ge $RetryCount)
            {
                throw "HPC Cluster ($ConnectionString) is not ready after $RetryCount connection attempts: $_"
            }
            else
            {
                Write-Verbose "HPC Cluster is not ready yet, wait for $RetryIntervalSec seconds ..."
                Start-Sleep -Seconds $RetryIntervalSec
            }
        }
    }
}

function Test-TargetResource
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $ConnectionString,

        [Parameter(Mandatory=$false)]
        [UInt64]$RetryIntervalSec = 20,

        [Parameter(Mandatory=$false)]
        [UInt32]$RetryCount = 30
    )
    
    try
    {
        AddHPCPshModules  | Out-Null
        Get-HpcClusterRegistry -Scheduler $ConnectionString -ErrorAction Stop  | Out-Null
        return $true
    }
    catch
    {
        Write-Verbose "HPC Management service not started, cluster is not ready yet: $_"
        return $false
    }
}

function AddHPCPshModules
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

Export-ModuleMember -Function *-TargetResource
