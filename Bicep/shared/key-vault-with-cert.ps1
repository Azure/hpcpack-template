Param(
  [Alias("v")]
  [string] $vaultName,
  [Alias("c")]
  [string] $commonName = "HPCPackCommunication",
  [Alias("n")]
  [string] $certName = "HPCPackCommunication"
)

$ErrorActionPreference = 'Stop'

if($commonName.StartsWith("CN="))
{
    $subjectName = $commonName
}
else
{
    $subjectName = "CN=$commonName"
}

"Create a self-signed certificate '$certName' in the Azure Key Vault '$vaultName' with subject name '$subjectName'." | Out-Default

$certPolicy = New-AzKeyVaultCertificatePolicy -SecretContentType "application/x-pkcs12" -SubjectName $subjectName -IssuerName "Self" -ValidityInMonths 60 -ReuseKeyOnRenewal -KeyUsage DigitalSignature, KeyAgreement, KeyEncipherment, KeyCertSign -Ekus "1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2"

Add-AzKeyVaultCertificate -VaultName $vaultName -Name $certName -CertificatePolicy $certPolicy

"Waiting for the certificate to be ready..." | Out-Default
Start-Sleep -Seconds 5

$keyVaultCert = Get-AzKeyVaultCertificate -VaultName $vaultName -Name $certName
while(!$keyVaultCert.Thumbprint -or !$keyVaultCert.SecretId)
{
    Start-Sleep -Seconds 2
    $keyVaultCert = Get-AzKeyVaultCertificate -VaultName $vaultName -Name $certName
}
"The Azure Key Vault certificate '$certName' is ready for use." | Out-Default

$DeploymentScriptOutputs = @{
  thumbprint = $keyVaultCert.Thumbprint
  url = $keyVaultCert.SecretId
}

$DeploymentScriptOutputs | Out-Default
