# Azure HPC Pack Templates

Azure HPC Pack templates make it easy to deploy an HPC Pack cluster on Azure.

## Templates

There are two kinds of templates in this repo: one is in Bicep and the other one is in traditional JSON.

* [Bicep templates](./Bicep/)
* [JSON templates](./GeneratedTemplates/)

Bicep is recommended for better deployment and development experiences, with excellent tooling in VS Code, while the traditional JSON is kept for easy web deployment without VS Code.

> Note
>
> The templates in this repo are only for HPC Pack 2019. For legacy HPC Pack versions, please see
>
> * [Microsoft HPC Pack 2016 Update 3](https://github.com/azure/hpcpack-template-2016)
> * [Microsoft HPC Pack 2012 R2 Update 3](https://github.com/azure/hpcpack-template-2012r2)

## Logging to Azure Monitor

HPC Pack templates now integrate with Azure Monitor and can make logs to it, which makes it much more convenient than ever to diagnose problems and watch the health of a HPC Pack cluster on Azure. See [this document](./Docs/AzureMonitor.md) for the details.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
