∩╗┐<#
.Synopsis
    Updates the authentication key configuration on HPC Pack head node(s), used for securing communication between the head node and Linux compute nodes.

.DESCRIPTION
    This script updates the authentication key configuration on HPC Pack head nodes(s) used for securing communication between head node(s) and Linux compute nodes.
    Needs to be same as ClusterAuthenticationKey in /opt/hpcnodemanager/nodemanager.json on all Linux compute nodes.

.NOTES
    This cmdlet requires that the current machine is a head node in an HPC Pack 2016 or later cluster.

.EXAMPLE
    Update the Linux authentication key for this HPC Pack cluster.
    PS > Update-HpcLinuxAuthenticationKey.ps1 -AuthenticationKey TestAuthKey
#>
Param
(
    # The AuthenticationKey of the HPC Pack cluster for Linux compute node communication. Needs to be same as ClusterAuthenticationKey in /opt/hpcnodemanager/nodemanager.json on Linux compute nodes.
    [Parameter(Mandatory = $true, ParameterSetName = "AuthenticationKey")]
    [ValidateNotNullOrEmpty()]
    [String] $AuthenticationKey,

    # The log file path, if not specified, the log will be generated in system temp folder.
    [Parameter(Mandatory = $false)]
    [String] $LogFile
)

$curUser = [Security.Principal.WindowsIdentity]::GetCurrent();
if (-not (New-Object Security.Principal.WindowsPrincipal $curUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "You must run this script with administrator privileges"
}

$VerbosePreference = "Continue"
$datestr = Get-Date -Format "yyyy_MM_dd-HH_mm_ss"
if (-not $LogFile) {
    $LogFile = "$env:windir\Temp\Update-HpcLinuxAuthenticationKey-$datestr.log"
}

function WriteLog {
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String] $Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Verbose")]
        [String] $LogLevel = "Verbose"
    )
    
    $timestr = Get-Date -Format 'MM/dd/yyyy HH:mm:ss'
    $NewMessage = "$timestr - $Message"
    switch ($LogLevel) {
        "Error" { Write-Error   $NewMessage; break }
        "Warning" { Write-Warning $NewMessage; break }
        "Verbose" { Write-Verbose $NewMessage; break }
    }
       
    try {
        $NewMessage = "[$LogLevel]$timestr - $Message"
        Add-Content $LogFile $NewMessage -ErrorAction SilentlyContinue
    }
    catch {
        #Ignore the error
    }
}

try {
    $HPCKeyPath = "HKLM:\SOFTWARE\Microsoft\HPC"
    $HPCWow6432KeyPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\HPC"
    $roleItem = $null
    $keyExists = Test-Path -Path $HPCKeyPath
    if ($keyExists) {
        $roleItem = Get-ItemProperty -Name InstalledRole -LiteralPath $HPCKeyPath -ErrorAction SilentlyContinue
        $hnListItem = Get-ItemProperty -Name ClusterConnectionString -LiteralPath $HPCKeyPath -ErrorAction SilentlyContinue
    }

    if ((-not $keyExists) -or ($null -eq $roleItem) -or ($null -eq $hnListItem)) {
        throw "This computer($env:ComputerName) is not a valid HPC cluster node"
    }

    $isHeadNode = ($roleItem.InstalledRole -contains 'HN')
    $serviceFabricHN = $false
    if ($isHeadNode -and $hnListItem.ClusterConnectionString.Contains(',')) {
        # For multiple head node, we check whether it is a service fabric cluster or new HA cluster
        $hpcSecKeyItem = Get-Item -Path HKLM:\SOFTWARE\Microsoft\HPC\Security -ErrorAction SilentlyContinue
        $serviceFabricHN = ($null -eq $hpcSecKeyItem) -or ($hpcSecKeyItem.Property -notcontains "HAStorageDbConnectionString")
    }

    # Get the current HPC Pack version by HpcCommon.dll file version (major version 5 for HPC Pack 2016, 6 for HPC Pack 2019)
    $ccpHome = [Environment]::GetEnvironmentVariable("CCP_HOME", 'Machine')
    $hpcCommonDll = [IO.Path]::Combine($ccpHome, 'Bin\HpcCommon.dll')
    $versionStr = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($hpcCommonDll).FileVersion
    $hpcVersion = New-Object System.Version $versionStr

    WriteLog "The current Installed HPC Role(s): $($roleItem.InstalledRole)" -LogLevel Verbose

    WriteLog "Updating the HPC authentication key in Registry Table on $env:ComputerName" -LogLevel Verbose

    if ($isHeadNode -and (($hpcVersion.Major -eq 6) -or $serviceFabricHN)) {
        # For HPC Pack 2019 head node or SF head node, set cluster registry as well
        Set-HpcClusterRegistry -PropertyName ClusterAuthenticationKey -PropertyValue $AuthenticationKey
    }
    Set-ItemProperty -Path $HPCKeyPath -Name ClusterAuthenticationKey -Value $AuthenticationKey
    if (Test-Path $HPCWow6432KeyPath) {
        Set-ItemProperty -Path $HPCWow6432KeyPath -Name ClusterAuthenticationKey -Value $AuthenticationKey
    }

    if (-not (($hpcVersion.Major -ge 6) -and ($hpcVersion.Minor -ge 3))) {
        # overwrite linuxnode.json ARM template file with new authentication key if we are not in HPC Pack 2019 Update 3 or later
        WriteLog "Updating the linuxnode.json ARM template on $env:ComputerName" -LogLevel Verbose
        $hpcLinuxJson = [IO.Path]::Combine($ccpHome, 'Bin\linuxnode.json')
        $hpcLinuxJsonBackup = [IO.Path]::Combine($ccpHome, "Bin\linuxnode_backup_$datestr.json")
        WriteLog "Backup the original linuxnode.json to $hpcLinuxJsonBackup" -LogLevel Verbose
        Copy-Item -Path $hpcLinuxJson -Destination $hpcLinuxJsonBackup -Force
        # check if "parameters" include "ClusterAuthenticationKey"
        $jsonContent = Get-Content -Path $hpcLinuxJson -Raw
        $jsonObj = ConvertFrom-Json $jsonContent
        $jsonObj.parameters | Add-Member -Type NoteProperty -Name ClusterAuthenticationKey -Value @{"type" = "securestring"; "defaultValue" = $AuthenticationKey;
            "metadata" = @{"description" = "The authentication key of the HPC Pack cluster for Linux compute node communication." }
        } -Force
        # Iterate through resources to find one with "type" of "Microsoft.Compute/virtualMachines"
        $jsonObj.resources | ForEach-Object {
            if ($_.type -eq "Microsoft.Compute/virtualMachines") {
                # go through its resources to find one whose "name" contains "installHPCNodeAgent"
                $_.resources | ForEach-Object {
                    if ($_.name -like "*installHPCNodeAgent*") {
                        $_.properties.typeHandlerVersion = "16.3"
                        $_.properties.settings | Add-Member -Type NoteProperty -Name "ProtectedSettings" -Value @{"AuthenticationKey" = "[parameters('authenticationKey')]"} -Force
                    }
                }
            }
        }
        # Save the updated json file
        $jsonObj | ConvertTo-Json -Depth 100 | Set-Content -Path $hpcLinuxJson
    }

    $hpcServices = @("HpcManagement", "HpcBroker", "HpcDeployment", "HpcDiagnostics", "HpcFrontendService",
        "HpcMonitoringClient", "HpcMonitoringServer", "HpcNamingService", "HpcNodeManager", "HpcReporting", "HpcScheduler",
        "HpcSession", "HpcSoaDiagMon", "HpcWebService")

    # Check the existence of the HPC Services and restart them
    $restartFailure = $false
    foreach ($svcname in $hpcServices) {
        $service = Get-Service -Name $svcname -ErrorAction SilentlyContinue
        if ($null -eq $service) {
            continue
        }

        if (($service.StartType -eq [ServiceProcess.ServiceStartMode]::Automatic) -or ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::Running)) {
            WriteLog "Restarting service: $svcname" -LogLevel Verbose
            Restart-Service -Name $svcname -Force
            if (-not $?) {
                $restartFailure = $true
                WriteLog ("Failed to restart HPC service: $svcname : " + $Error[0]) -LogLevel Warning
            }
        }
    }

    if (-not $restartFailure) {
        WriteLog "Successfully updated HPC Linux authentication key." -LogLevel Verbose
    }
    else {
        Write-Warning "One or more HPC services fail to restart, you can try to manually restart them or reboot the machine."
    }
}
catch {
    WriteLog "Failed to update HPC Linux authentication key : $_" -LogLevel Error
    throw
}
