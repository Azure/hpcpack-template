# Bicep Templates

## Deploy to Azure

### Prerequisites

You need the followings for your deployment in Bicep

* [Bicep tools](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)

  There're several options of Bicep tools. Among these, VS Code + Bicep extension is recommended for authoring and deploying. Azure CLI and Azure PowerShell can be used for automatic scripts.

* [A certificate in Azure Key Vault](../Prerequisites.md)

### Templates that are integrated with Active Directory Domain

1. [High-availability cluster for Windows workloads with new Active Directory Domain](./new-2hn-wincn-ad.bicep)

   This template deploys an HPC Pack cluster with high availability for Windows HPC workloads in Active Directory Domain forest. The cluster includes one domain controller, **two** head nodes, one Database Server with SQL Server 2016 Standard version, and a configurable number of **Windows** compute nodes.

2. [High-availability cluster for Windows workloads with existing Active Directory Domain](./new-2hn-wincn-existing-ad.bicep)

   This template deploys an HPC Pack cluster with high availability for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes **two** head nodes, one Database Server with SQL Server 2016 Standard version, and a configurable number of **Windows** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

3. [High-availability cluster with Azure SQL databases for Windows workloads with existing Active Directory Domain](./new-2hn-wincn-existing-ad-azuresql.bicep)

   This template deploys an HPC Pack cluster with high availability for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes **two** head nodes, SQL Azure databases, and a configurable number of **Windows** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

   ***Note***: Make sure you have enabled **service endpoint for Azure SQL Database(Microsoft.Sql)** on the subnet in which you want to create the cluster.

4. [Single head node cluster for Windows workloads with new Active Directory Domain](./new-1hn-wincn-ad.bicep)

   This template deploys an HPC Pack cluster with one **single** head node for Windows HPC workloads in Active Directory Domain forest. The cluster includes one domain controller, one **single** head node with local databases (SQL server 2019 Express version), and a configurable number of **Windows** compute nodes.

5. [Single head node cluster for Windows workloads with existing Active Directory Domain](./new-1hn-wincn-existing-ad.bicep)

   This template deploys an HPC Pack cluster with one **single** head node for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes one **single** head node with local databases (SQL server 2019 Express version), and a configurable number of **Windows** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

6. [Single head node cluster for Linux workloads with existing Active Directory Domain](./new-1hn-lnxcn-existing-ad.bicep)

   This template deploys an HPC Pack cluster with one **single** head node for Windows HPC workloads in an existing Active Directory Domain forest. The cluster includes one **single** head node with local databases (SQL server 2019 Express version), and a configurable number of **Linux** compute nodes. You can choose not to create public IP address for the head node if you have a virtual network with Express Route configured and you want to join the cluster to your on-premises Active Directory Domain.

### Templates that are NOT integrated with Active Directory Domain

> Note
>
> The HPC Pack cluster without Active Directory Domain integrated only supports limited feature set, you shall use it only for Experimentation/Testing purposes.

1. [Single head node cluster for Windows workloads](./new-1hn-wincn-no-ad.bicep)

   This template deploys an HPC Pack cluster with one **single** head node and a configurable number of **Windows** compute nodes. The head node is with local databases (SQL server 2019 Express version).

2. [Single head node cluster for Linux workloads](./new-1hn-lnxcn-no-ad.bicep)

   This template deploys an HPC Pack cluster with one **single** head node and a configurable number of **Linux** compute nodes. The head node is with local databases (SQL server 2019 Express version).

## For developers

### File Naming Conventions

Follow the file naming conventions when you add new Bicep files.

* For a file that creates a new cluster, name the file like `new-{1|2}hn-{win|lnx}cn[-{existing|no}]-ad[-{xxx}].bicep`. For example, `new-1hn-wincn-ad.bicep` is for a new cluster of Windows compute nodes and a new Active Domain; `new-2hn-wincn-existing-ad-azuresql.bicep` is for a new cluster of Windows compute nodes and an existing Active Domain, using Azure SQL database.
* For a file that adds nodes to existing cluster, name the file like `add-xxx-nodes.bicep`. For example, `add-lnx-compute-nodes.bicep` is for adding Linux compute nodes.

### Compile Bicep to JSON templates

Compile the Bicep templates to JSON templates by `bicep.csproj`, with .NET SDK 8 or later.