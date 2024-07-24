<#
.Synopsis
    Create or import a new Azure Key Vault Certificate for HPC Pack Cluster

.DESCRIPTION
    This script creates or imports an Azure Key Vault certificate which is used to deploy HPC Pack cluster in Azure, it creates the Azure resource group and the Azure Key Vault as well if they do not exist.
    Author :  Microsoft HPC Pack team
    Version:  1.0.0

.Example
    .\CreateHpcKeyVaultCertificate.ps1 -VaultName myhpckeyvault -Name hpcnodecomm -ResourceGroup myhpckeyvaultrg -Location japaneast -CommonName "HPC Pack Node Communication"
    
    Above command creates a new self-signed certificate 'hpcnodecomm' in Azure Key Vault 'myhpckeyvault'

.Example
    $mypwd = Read-Host -AsSecureString -Prompt "Protection password of Pfx file"
    .\CreateHpcKeyVaultCertificate.ps1 -VaultName myhpckeyvault -Name hpcnodecomm -ResourceGroup myhpckeyvaultrg -Location japaneast -PfxFilePath "d:\hpcnodecomm.pfx" -Password $mypwd

    Above command imports the PFX certificate d:\hpcnodecomm.pfx as certificate 'hpcnodecomm' to Azure Key Vault 'myhpckeyvault'.
#>
[CmdletBinding(DefaultParameterSetName="CreateNewCertificate")]  
Param
(
    # Specifies the Azure Key Vault name in which the certificate will be created. The script will create the Azure Key Vault if it does not exist.
    [Parameter(Mandatory=$true, ParameterSetName="ImportPfxCertificate")]
    [Parameter(Mandatory=$true, ParameterSetName="CreateNewCertificate")]
    [String] $VaultName,

    # Specifies the Azure key vault certificate name to be created.
    [Parameter(Mandatory=$true, ParameterSetName="ImportPfxCertificate")]
    [Parameter(Mandatory=$true, ParameterSetName="CreateNewCertificate")]
    [String] $Name,

    # Specifies the Azure resource group name in which the Azure key vault will be created. The script will create the Azure resource group if it does not exist.
    [Parameter(Mandatory=$true, ParameterSetName="ImportPfxCertificate")]
    [Parameter(Mandatory=$true, ParameterSetName="CreateNewCertificate")]
    [String] $ResourceGroup,

    # Specifies the Azure location in which the Azure key vault will be created.
    [Parameter(Mandatory=$true, ParameterSetName="ImportPfxCertificate")]
    [Parameter(Mandatory=$true, ParameterSetName="CreateNewCertificate")]
    [String] $Location,

    # Specifies the name or Id of the Azure subscription in which the Azure key vault will be created. If not specified, the current Azure subscription will be selected.
    [Parameter(Mandatory=$false, ParameterSetName="ImportPfxCertificate")]
    [Parameter(Mandatory=$false, ParameterSetName="CreateNewCertificate")]
    [String] $Subscription = "",

    # Specifies the common name of the self-signed certificate to be created, the default value is "HPC Pack Node Communication".
    [Parameter(Mandatory=$false, ParameterSetName="CreateNewCertificate")]
    [String] $CommonName = "HPC Pack Node Communication",

    # Specifies the absolute path of the Pfx certificate file to be imported.
    [Parameter(Mandatory=$true, ParameterSetName="ImportPfxCertificate")]
    [String] $PfxFilePath,

    # Specifies protection password of the Pfx certificate file.
    [Parameter(Mandatory=$true, ParameterSetName="ImportPfxCertificate")]
    [SecureString] $Password
)

Write-Host "Validating the input parameters ..." -ForegroundColor Green
[System.Net.ServicePointManager]::SecurityProtocol = 'tls,tls11,tls12'
$azContext = Get-AzContext -ErrorAction Stop
if($azContext.Account.Type -ne "User")
{
    throw "The script cannot be run with an Azure service principal or managed identity, please run 'Connect-AzAccount' to login as an Azure user account and retry."
}

if($Subscription)
{
    if(($azContext.Subscription.Name -ne $Subscription) -and ($azContext.Subscription.Id -ne $Subscription))
    {
        Set-AzContext -Subscription $Subscription -ErrorAction Stop
    }
}
else 
{
    Write-Warning "'Subscription' is not specified, the Azure Key Vault certificate will be created in the current Azure subscription $($azContext.Subscription.Name) ($($azContext.Subscription.Id))"
}
if ($PSBoundParameters.ContainsKey('PfxFilePath'))
{
    #Validate the pfx file and password
    try 
    {
        $pfxCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $PfxFilePath, $Password
    }
    catch [System.Management.Automation.MethodInvocationException]
    {
        throw $_.Exception.InnerException
    }

    $pfxCert.Dispose()
}

if($Location.Contains(' '))
{
    $azLocations = Get-AzLocation
    $loc = $azLocations | ?{$_.Location -eq $Location -or $_.DisplayName -eq $Location}
    if($null -eq $loc)
    {
        throw "The Azure Location '$Location' is invalid"
    }
    $Location = $loc.Location
}
$Location = $Location.ToLower()

$keyVault = Get-AzKeyVault -VaultName $VaultName -ErrorAction SilentlyContinue
if($keyVault)
{
    if($keyVault.Location -ne $Location)
    {
        throw "The Azure Key Vault $VaultName already exists in another location $($keyVault.Location)."
    }
    if($keyVault.ResourceGroupName -ne $ResourceGroup)
    {
        throw "The Azure Key Vault $VaultName already exists in another resource group $($keyVault.ResourceGroupName)."
    }
    Write-Host "The Azure Key Vault '$VaultName' already exists." -ForegroundColor Green
    if(!$keyVault.EnabledForDeployment -or !$keyVault.EnabledForTemplateDeployment)
    {
        Write-Host "Set EnabledForDeployment and EnabledForTemplateDeployment for the Azure Key Vault '$VaultName'." -ForegroundColor Green
        Set-AzKeyVaultAccessPolicy -VaultName $VaultName -EnabledForDeployment -EnabledForTemplateDeployment -ErrorAction Stop
    }
}
else
{
    $rg = Get-AzResourceGroup -Name $ResourceGroup -Location $Location -ErrorAction SilentlyContinue
    if($null -eq $rg)
    {
        Write-Host "Create the Azure resource group '$ResourceGroup' in the Azure Location '$Location'" -ForegroundColor Green
        $rg = New-AzResourceGroup -Name $ResourceGroup -Location $Location
    }

    Write-Host "Create the Azure Key Vault '$VaultName' in the Azure resource group '$ResourceGroup'." -ForegroundColor Green
    $keyVault = New-AzKeyVault -Name $VaultName -ResourceGroupName $ResourceGroup -Location $location -EnabledForDeployment -EnabledForTemplateDeployment -ErrorAction Stop
}

if ($PSBoundParameters.ContainsKey('PfxFilePath'))
{
    Write-Host "Import the certificate to the Azure Key Vault '$VaultName' as Azure Key Vault Certificate '$Name'." -ForegroundColor Green
    $keyVaultCert = Import-AzKeyVaultCertificate -VaultName $VaultName -Name $Name -FilePath $PfxFilePath -Password $Password -ErrorAction Stop
    Write-Host "The certificate '$Name' is successfully imported." -ForegroundColor Green
}
else
{
    if($CommonName.StartsWith("CN="))
    {
        $subjectName = $CommonName
    }
    else
    {
        $subjectName = "CN=$CommonName"
    }
    Write-Host "Create a self-signed certificate '$Name' in the Azure Key Vault '$VaultName' with subject name '$subjectName'." -ForegroundColor Green
    $certPolicy = New-AzKeyVaultCertificatePolicy -SecretContentType "application/x-pkcs12" -SubjectName $subjectName -IssuerName "Self" -ValidityInMonths 60 -ReuseKeyOnRenewal -KeyUsage DigitalSignature, KeyAgreement, KeyEncipherment, KeyCertSign -Ekus "1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2"
    $null = Add-AzKeyVaultCertificate -VaultName $VaultName -Name $Name -CertificatePolicy $certPolicy -ErrorAction Stop
    Write-Host "Waiting for the certificate to be ready..." -ForegroundColor Green
    Start-Sleep -Seconds 5
    $keyVaultCert = Get-AzKeyVaultCertificate -VaultName $VaultName -Name $Name
    while(!$keyVaultCert.Thumbprint -or !$keyVaultCert.SecretId)
    {
        Start-Sleep -Seconds 2
        $keyVaultCert = Get-AzKeyVaultCertificate -VaultName $VaultName -Name $Name
    }
    Write-Host "The Azure Key Vault certificate '$Name' is ready for use." -ForegroundColor Green
}

Write-Host "Below is the information of the Azure Key Vault Certificate which you shall specify in the deployment template:" -ForegroundColor Yellow
"Vault Name           : $VaultName"
"Vault Resource Group : $ResourceGroup"
"Certificate URL      : $($keyVaultCert.SecretId)"
"Cert Thumbprint      : $($keyVaultCert.Thumbprint)"