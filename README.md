# Azure Image Builder Demo for Windows Server 2019 and Windows 10 Multi-Session images


The repo provides code to create [Azure Image Builder (AIB)](https://docs.microsoft.com/azure/virtual-machines/image-builder-overview) environment through Azure Pipelines leveraging Azure Bicep templates. Two (2) Azure pipelines created to create the following images: 
&nbsp;
 -  Windows Server 2019 image with the latest Windows Updates and Azure Windows Baseline applied using the guest configuration feature of Azure Policy. 

 -  Windows 10 Multi-session 21H1 Gen 1 image with FSLogix and Teams installed. Latest Windows updates. As well as optimization for Azure Virtual Desktop leveraging [Virtual Desktop Optimization Tool](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool). 

## Overview 

The code provided is oriented to simplify the setup of Proof-of-Concept environments or setting up demos for Azure Image Builder and Azure Shared Image Gallery. Each image has dedicated Azure pipeline and main Bicep template - to provide the independent lifecycle and management for each. All resources are deployed into the same Resource Group and Subscription. 

AIB resources are created in East US 2 region. As the service is available in [select regions](https://docs.microsoft.com/azure/virtual-machines/image-builder-overview#regions). 

The customization scripts used for the images are uploaded to the storage account specified in [common.yml in '/config/common'](/config/variables) as part of the Azure pipeline run. The storage account is assumed to be in the same subscription as the AIB demo deployment. If creating new storage account - ensure its same region as AIB resource. In this case - East US 2.

Images are published into Azure Shared Image Gallery (SIG) after build is completed. As part of the code - images replicated into Canada Central and East US 2. If using both images - then the same AIB and SIG would be used. 

The following resources are created during each image Azure Pipeline:

- user-assigned managed identity for running a deployment script
- role definition and role assignment to limit access of the new identity
- Azure Image Gallery with the selected image and its template
- deployment script to trigger the build of the custom image in Azure Image Builder

Image templates configurations are located in ['/bicep-modules/images'](/bicep-modules/images). Feel free to customize the existing and/or add your own. 

Main Bicep templates for each image are located in the root of the repository. If making changes to customization - don't forget to update the corresponding main module as well. 


## Instructions to setup in Azure DevOps

> ### Pre-requisites: 
>
> - If leveraging your own private repository - fork [Virtual Desktop Optimization Tool](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool) into your >own   repository. And archive its contents into [master.zip](https://github.com/nataliakon/Virtual-Desktop-Optimization-Tool/blob/main/master.zip) and place it in the forked [repository](https://github.com/nataliakon/Virtual-Desktop-Optimization-Tool). This would ensure you have option to keep up the changes from Virtual Desktop team at your own >pace. 
> 
> - [Create](https://docs.microsoft.com/cli/azure/create-an-azure-service-principal-azure-cli) or re-use service principal and assign RBAC role of [Owner](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#owner) to the subscription. 
>
> - Create (or reuse existing) storage account to upload and use the customization scripts. 
> - Assign role of ['Storage Account Contributor'](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#storage-account-contributor) for the storage account to Service Principal created above (used for Azure Pipelines)


### Steps: 

- Create the Azure DevOps Project. If leveraging Github as code repository with Azure Pipelines - follow instructions [here](https://www.azuredevopslabs.com/labs/azuredevops/github-integration/) to setup.

- [Configure Service Connection in Azure DevOps Project](https://docs.microsoft.com/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml)

- Update  [common.yml in '/config/common'](/config/variables) with your values. 

- Create Azure Pipelines for the image(s): 
  + Go to Pipelines
  + New Pipeline
  + Choose Azure Repos Git or GitHub
  + Select Repository
  + Select Existing Azure Pipeline YAML file
  + Identify the pipeline in `.pipelines`:
     + For Windows 10 Multi-Session: `.pipelines\build-win-10-multisession-AVD-image.yml`
     + For Windows Server 2019: `.pipelines\build-win-server-2019-image.yml`
  + Save the pipeline (don't run it yet) 
  + Rename the pipeline to name that would identify it (i.e. Build Windows Server 2019 when creating the pipeline for it)
  
- Run the pipeline. It also includes the stage for checking the status of the image build. It will hold the Azure pipeline until the image build status is 'Succeeded'. 




