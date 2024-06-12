# Function to check if the registry key exists
function Test-RegistryKeyExists {
    param (
        [string]$Path
    )

    try {
        $key = Get-Item -Path $Path -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Function to create the registry key if it does not exist
function Ensure-RegistryKeyExists {
    param (
        [string]$Path
    )

    if (Test-RegistryKeyExists -Path $Path) {
        Write-Host "Registry key '$Path' already exists."
    } else {
        try {
            New-Item -Path $Path -Force | Out-Null
            Write-Host "Registry key '$Path' has been created."
        } catch {
            Write-Host "Failed to create registry key '$Path'. Error: $_"
        }
    }
}

# Function to set a registry value
function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Data
    )

    try {
        Set-ItemProperty -Path $Path -Name $Name -Value $Data -Type DWord -Force
        Write-Host "Registry value '$Name' set to '$Data' in '$Path'."
    } catch {
        Write-Host "Failed to set registry value '$Name' in '$Path'. Error: $_"
    }
}

$registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2"
Ensure-RegistryKeyExists -Path $registryKeyPath

$registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
Ensure-RegistryKeyExists -Path $registryKeyPath
$registryValueName = "Enabled"
$registryValueData = 1
Set-RegistryValue -Path $registryKeyPath -Name $registryValueName -Data $registryValueData

$registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
Ensure-RegistryKeyExists -Path $registryKeyPath
$registryValueName = "Enabled"
$registryValueData = 1
Set-RegistryValue -Path $registryKeyPath -Name $registryValueName -Data $registryValueData

$registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1"
Ensure-RegistryKeyExists -Path $registryKeyPath

$registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
Ensure-RegistryKeyExists -Path $registryKeyPath
$registryValueName = "Enabled"
$registryValueData = 0
Set-RegistryValue -Path $registryKeyPath -Name $registryValueName -Data $registryValueData

$registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
Ensure-RegistryKeyExists -Path $registryKeyPath
$registryValueName = "Enabled"
$registryValueData = 0
Set-RegistryValue -Path $registryKeyPath -Name $registryValueName -Data $registryValueData

$registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0"
Ensure-RegistryKeyExists -Path $registryKeyPath

$registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client"
Ensure-RegistryKeyExists -Path $registryKeyPath
$registryValueName = "Enabled"
$registryValueData = 0
Set-RegistryValue -Path $registryKeyPath -Name $registryValueName -Data $registryValueData

$registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server"
Ensure-RegistryKeyExists -Path $registryKeyPath
$registryValueName = "Enabled"
$registryValueData = 0
Set-RegistryValue -Path $registryKeyPath -Name $registryValueName -Data $registryValueData
