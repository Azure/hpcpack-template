# Deploy an HPC Pack cluster in Azure with Microsoft HPC Pack 2019 Update 1

## **Note:**

See [Pre-Requisites](#prerequisites) section on this page before starting your deployment.

---

## Following templates are Active Directory Domain integrated

### Template 1: High-availability cluster for Windows workloads with new Active Directory Domain

This template deploys an HPC Pack cluster with high availability for Windows HPC workloads in Active Directory Domain forest. The cluster includes one domain controller, **two** head nodes, one Database Server with SQL Server 2016 Standard version, and a configurable number of **Windows** compute nodes.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2F2019u2%2FHPCPack2019-Update1%2Fnewcluster-templates%2Ftwo-hns-wincn-ad.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Template 2: High-availability cluster for Windows workloads with existing Active Directory Domain

This template deploys an HPC Pack cluster with high availability for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes **two** head nodes, one Database Server with SQL Server 2016 Standard version, and a configurable number of **Windows** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2F2019u2%2FHPCPack2019-Update1%2Fnewcluster-templates%2Ftwo-hns-wincn-existing-ad.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Template 3: High-availability cluster with Azure SQL databases for Windows workloads with existing Active Directory Domain

This template deploys an HPC Pack cluster with high availability for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes **two** head nodes, SQL Azure databases, and a configurable number of **Windows** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

***Note***: Make sure you have enabled **service endpoint for Azure SQL Database(Microsoft.Sql)** on the subnet in which you want to create the cluster.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2F2019u2%2FHPCPack2019-Update1%2Fnewcluster-templates%2Ftwo-hns-wincn-existing-ad-sqlazure.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Template 4: Single head node cluster for Windows workloads with new Active Directory Domain

This template deploys an HPC Pack cluster with one **single** head node for Windows HPC workloads in Active Directory Domain forest. The cluster includes one domain controller, one **single** head node with local databases (SQL server 2019 Express version), and a configurable number of **Windows** compute nodes.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2F2019u2%2FHPCPack2019-Update1%2Fnewcluster-templates%2Fsingle-hn-wincn-dedicate-ad.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Template 5: Single head node cluster for Windows workloads with existing Active Directory Domain

This template deploys an HPC Pack cluster with one **single** head node for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes one **single** head node with local databases (SQL server 2019 Express version), and a configurable number of **Windows** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2F2019u2%2FHPCPack2019-Update1%2Fnewcluster-templates%2Fsingle-hn-wincn-existing-ad.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Template 6: Single head node cluster for Linux workloads with existing Active Directory Domain

This template deploys an HPC Pack cluster with one **single** head node for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes one **single** head node with local databases (SQL server 2019 Express version), and a configurable number of **Linux** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2F2019u2%2FHPCPack2019-Update1%2Fnewcluster-templates%2Fsingle-hn-lnxcn-existing-ad.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

---
## Following templates are NOT Active Directory Domain integrated

> **Note**
>
> The HPC Pack cluster without Active Directory Domain integrated only supports limited feature set, you shall use it only for Experimentation/Testing purposes.



### Template 1: Single head node cluster for Windows workloads

This template deploys an HPC Pack cluster with one **single** head node and a configurable number of **Windows** compute nodes. The head node is with local databases (SQL server 2019 Express version).

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2F2019u2%2FHPCPack2019-Update1%2Fnewcluster-templates%2Fsingle-hn-wincn-noad.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Template 2: Single head node cluster for Linux workloads

This template deploys an HPC Pack cluster with one **single** head node and a configurable number of **Linux** compute nodes. The head node is with local databases (SQL server 2019 Express version).

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2F2019u2%2FHPCPack2019-Update1%2Fnewcluster-templates%2Fsingle-hn-lnxcn.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

---
## <a name="prerequisites"></a>Pre-Requisites:

An Azure Key Vault Certificate is required to deploy Microsoft HPC Pack 2019 cluster in Azure, it must be created in the **same Azure location** where the HPC Pack cluster will be deployed. The certificate will be installed on all the HPC nodes during the deployment, it is used to secure the communication between the HPC nodes. The certificate must meet the following requirements:

* It must have a private key capable of **key exchange**
* Key usage includes **Digital Signature** and **Key Encipherment**
* Enhanced key usage includes **Client Authentication** and **Server Authentication**

If you don't have an existing Azure Key Vault certificate which meets the above requirements, you shall either import a PFX certificate file to Azure Key Vault or directly generate a new Azure Key Vault certificate. 

### Create Azure Key Vault Certificate on [Azure Portal](https://portal.azure.com) 

1. Select an existing Azure key vault or [Create](https://portal.azure.com/#create/Microsoft.KeyVault) a new Azure Key Vault in the location where the HPC Pack cluster will be deployed, make sure to enable access to **Azure Virtual Machines for deployment** and **Azure Resource Manager for template deployment** in the **Access policies** setting. And record the **Vault Name**, **Vault Resource Group**.

2. Click the Azure key vault, choose **Settings** -> **Certificates** -> **Generate/Import**, and following the wizard to generate or import the certificate.

![New self-signed key vault certificate](https://docs.microsoft.com/powershell/media/hpcpack-cluster/generateazurekeyvaultcertificate.png)

3. After the certificate is created, click into the current certificate version, record ***X.509 SHA-1 Thumbprint***  as **Cert Thumbprint**, and ***Secret Identifier*** (but not ***Certificate Identifier***) as **Certificate URL**.

### Create Azure Key Vault Certificate with PowerShell

Install [Azure PowerShell module](https://docs.microsoft.com/powershell/azure/install-az-ps) on your computer, run the following PowerShell commands to either generate or import an Azure Key Vault Certificate. And record the output **Vault Name**, **Vault Resource Group**, **Certificate URL**, and **Cert thumbprint** values.

Generate a new self-signed Azure Key Vault certificate:

```powershell
wget https://raw.githubusercontent.com/Azure/hpcpack-template/2019u2/Scripts/CreateHpcKeyVaultCertificate.ps1
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
Connect-AzAccount
.\CreateHpcKeyVaultCertificate.ps1 -VaultName <vaultName> -Name <certName> -ResourceGroup <resourceGroupName> -Location <azureLocation> -CommonName "HPC Pack Node Communication"
```

Import an existing PFX certificate file to Azure Key Vault

```powershell
wget https://raw.githubusercontent.com/Azure/hpcpack-template/2019u2/Scripts/CreateHpcKeyVaultCertificate.ps1
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
Connect-AzAccount
.\CreateHpcKeyVaultCertificate.ps1 -VaultName <vaultName> -Name <certName> -ResourceGroup <resourceGroupName> -Location <azureLocation> -PfxFilePath <filePath>
```

---

## <a name="knownissues"></a>Known Issues

### 1. Deployment failed due to nested deployment 'msiKeyVaultRoleAssignment*' failure

If you enable Managed Identity on the head node(s), in some rare conditions, the deployment may fail in the nested deployment named ***'msiKeyVaultRoleAssignment', 'msiKeyVaultRoleAssignment1', or 'msiKeyVaultRoleAssignment2'*** with error message ***"Tenant ID, application ID, principal ID, and scope are not allowed to be updated."***. In that case, you can go to [Azure Portal](https://portal.azure.com/), find the Azure Key Vault you are using, delete the unknown identities under **Access control(IAM) -> Role assignments -> Key Vault Contributor** and re-run the deployment.
