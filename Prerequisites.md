# Prerequisites

An Azure Key Vault Certificate is required to deploy Microsoft HPC Pack cluster in Azure, it must be created in the **same Azure location** where the HPC Pack cluster will be deployed. The certificate will be installed on all the HPC nodes during the deployment, it is used to secure the communication between the HPC nodes. The certificate must meet the following requirements:

* It must have a private key capable of **key exchange**
* Key usage includes **Digital Signature**, **Key Encipherment**, **Key Agreement** and **Certificate Signing**
* Enhanced key usage includes **Client Authentication** and **Server Authentication**

If you don't have an existing Azure Key Vault certificate which meets the above requirements, you shall either import a PFX certificate file to Azure Key Vault or directly generate a new Azure Key Vault certificate.

## Create Azure Key Vault Certificate on [Azure Portal](https://portal.azure.com)

1. Select an existing Azure key vault or [Create](https://portal.azure.com/#create/Microsoft.KeyVault) a new Azure Key Vault in the location where the HPC Pack cluster will be deployed, make sure to enable access to **Azure Virtual Machines for deployment** and **Azure Resource Manager for template deployment** in the **Access policies** setting. And record the **Vault Name**, **Vault Resource Group**.

2. Click the Azure key vault, choose **Settings** -> **Certificates** -> **Generate/Import**, and following the wizard to generate or import the certificate.

![New self-signed key vault certificate](https://docs.microsoft.com/powershell/media/hpcpack-cluster/generateazurekeyvaultcertificate.png)

3. After the certificate is created, click into the current certificate version, record ***X.509 SHA-1 Thumbprint***  as **Cert Thumbprint**, and ***Secret Identifier*** (but not ***Certificate Identifier***) as **Certificate URL**.

## Create Azure Key Vault Certificate with PowerShell

Install [Azure PowerShell module](https://docs.microsoft.com/powershell/azure/install-az-ps) on your computer, run the following PowerShell commands to either generate or import an Azure Key Vault Certificate. And record the output **Vault Name**, **Vault Resource Group**, **Certificate URL**, and **Cert thumbprint** values.

Generate a new self-signed Azure Key Vault certificate:

```powershell
wget https://raw.githubusercontent.com/Azure/hpcpack-template/master/Scripts/CreateHpcKeyVaultCertificate.ps1
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
Connect-AzAccount
.\CreateHpcKeyVaultCertificate.ps1 -VaultName <vaultName> -Name <certName> -ResourceGroup <resourceGroupName> -Location <azureLocation> -CommonName "HPC Pack Node Communication"
```

Import an existing PFX certificate file to Azure Key Vault

```powershell
wget https://raw.githubusercontent.com/Azure/hpcpack-template/master/Scripts/CreateHpcKeyVaultCertificate.ps1
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
Connect-AzAccount
.\CreateHpcKeyVaultCertificate.ps1 -VaultName <vaultName> -Name <certName> -ResourceGroup <resourceGroupName> -Location <azureLocation> -PfxFilePath <filePath>
```

## <a name="knownissues"></a>Known Issues

### Deployment failed due to nested deployment 'msiKeyVaultRoleAssignment*' failure

If you enable Managed Identity on the head node(s), in some rare conditions, the deployment may fail in the nested deployment named ***'msiKeyVaultRoleAssignment', 'msiKeyVaultRoleAssignment1', or 'msiKeyVaultRoleAssignment2'*** with error message ***"Tenant ID, application ID, principal ID, and scope are not allowed to be updated."***. In that case, you can go to [Azure Portal](https://portal.azure.com/), find the Azure Key Vault you are using, delete the unknown identities under **Access control(IAM) -> Role assignments -> Key Vault Contributor** and re-run the deployment.