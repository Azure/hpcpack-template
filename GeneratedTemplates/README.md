# JSON Templates

## Deploy to Azure

### Templates that are integrated with Active Directory Domain

1. High-availability cluster for Windows workloads with new Active Directory Domain

   This template deploys an HPC Pack cluster with high availability for Windows HPC workloads in Active Directory Domain forest. The cluster includes one domain controller, **two** head nodes, one Database Server with SQL Server 2016 Standard version, and a configurable number of **Windows** compute nodes.

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2Fmaster%2FGeneratedTemplates%2Fnew-2hn-wincn-ad.json" target="_blank">
       <img src="https://aka.ms/deploytoazurebutton"/>
   </a>

2. High-availability cluster for Windows workloads with existing Active Directory Domain

   This template deploys an HPC Pack cluster with high availability for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes **two** head nodes, one Database Server with SQL Server 2016 Standard version, and a configurable number of **Windows** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2Fmaster%2FGeneratedTemplates%2Fnew-2hn-wincn-existing-ad.json" target="_blank">
       <img src="https://aka.ms/deploytoazurebutton"/>
   </a>

3. High-availability cluster with Azure SQL databases for Windows workloads with existing Active Directory Domain

   This template deploys an HPC Pack cluster with high availability for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes **two** head nodes, SQL Azure databases, and a configurable number of **Windows** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

   ***Note***: Make sure you have enabled **service endpoint for Azure SQL Database(Microsoft.Sql)** on the subnet in which you want to create the cluster.

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2Fmaster%2FGeneratedTemplates%2Fnew-2hn-wincn-existing-ad-azuresql.json" target="_blank">
       <img src="https://aka.ms/deploytoazurebutton"/>
   </a>

4. Single head node cluster for Windows workloads with new Active Directory Domain

   This template deploys an HPC Pack cluster with one **single** head node for Windows HPC workloads in Active Directory Domain forest. The cluster includes one domain controller, one **single** head node with local databases (SQL server 2019 Express version), and a configurable number of **Windows** compute nodes.

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2Fmaster%2FGeneratedTemplates%2Fnew-1hn-wincn-ad.json" target="_blank">
       <img src="https://aka.ms/deploytoazurebutton"/>
   </a>

5. Single head node cluster for Windows workloads with existing Active Directory Domain

   This template deploys an HPC Pack cluster with one **single** head node for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes one **single** head node with local databases (SQL server 2019 Express version), and a configurable number of **Windows** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2Fmaster%2FGeneratedTemplates%2Fnew-1hn-wincn-existing-ad.json" target="_blank">
       <img src="https://aka.ms/deploytoazurebutton"/>
   </a>

6. Single head node cluster for Linux workloads with existing Active Directory Domain

   This template deploys an HPC Pack cluster with one **single** head node for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes one **single** head node with local databases (SQL server 2019 Express version), and a configurable number of **Linux** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2Fmaster%2FGeneratedTemplates%2Fnew-1hn-lnxcn-existing-ad.json" target="_blank">
       <img src="https://aka.ms/deploytoazurebutton"/>
   </a>

### Templates that are NOT integrated with Active Directory Domain

> Note
>
> The HPC Pack cluster without Active Directory Domain integrated only supports limited feature set, you shall use it only for Experimentation/Testing purposes.

1. Single head node cluster for Windows workloads

   This template deploys an HPC Pack cluster with one **single** head node and a configurable number of **Windows** compute nodes. The head node is with local databases (SQL server 2019 Express version).

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2Fmaster%2FGeneratedTemplates%2Fnew-1hn-wincn-no-ad.json" target="_blank">
       <img src="https://aka.ms/deploytoazurebutton"/>
   </a>

2. Single head node cluster for Linux workloads

   This template deploys an HPC Pack cluster with one **single** head node and a configurable number of **Linux** compute nodes. The head node is with local databases (SQL server 2019 Express version).

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fhpcpack-template%2Fmaster%2FGeneratedTemplates%2Fnew-1hn-lnxcn-no-ad.json" target="_blank">
       <img src="https://aka.ms/deploytoazurebutton"/>
   </a>

### Notes on deployed cluster

A few tags are added to VMs of a cluster to support

* The Key Vault and certificate used by the cluster. These tags have prefix "KV_"
  * KV_RG
  * KV_Name
  * KV_CertUrl
  * KV_CertThumbprint

* Logging to Azure Monitor. These tags have prefix "LA_"
  * LA_DceUrl
  * LA_DcrId
  * LA_DcrStream
  * LA_MiClientId
  * LA_MiResId

Do not change or remove these tags on VMs, or the function they support may be broken.

## For developers

The templates in this directory are generated from [Bicep templates](../Bicep/). So do not change the JSON templates here: change the source Bicep templates and generate JSON ones.