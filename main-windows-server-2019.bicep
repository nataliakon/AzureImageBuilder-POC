@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param storageaccountName string
param container string

@description('Resource group of the storage account for customizer script')

param storageaccountRG string


@description('The Azure region where resources in the template should be deployed.')
param location string = resourceGroup().location

@description('location for image definition')
param image_location string = 'eastus2'

@description('The name of the customizer script which will be executed during image build.')
param customizerScriptName string = '/s/scripts/runScript.ps1?'

@description('Name of the user-assigned managed identity used by Azure Image Builder template, and for triggering the Azure Image Builder build at the end of the deployment')
param templateIdentityName string = substring('ImageGallery_${guid(resourceGroup().id)}', 0, 21)

@description('Permissions to allow for the user-assigned managed identity.')
param templateIdentityRoleDefinitionName string = guid(resourceGroup().id)

@description('Name of the new Azure Image Gallery resource.')
param imageGalleryName string = substring('ImageGallery_${guid(resourceGroup().id)}', 0, 21)

@description('Detailed image information to set for the custom image produced by the Azure Image Builder build.')
param imageDefinitionProperties object = {
  name: 'Win2019_AzureWindowsBaseline_Definition'
  publisher: 'AzureWindowsBaseline'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
}

@description('Name of the template to create in Azure Image Builder.')
param imageTemplateName string = 'Win2019_AzureWindowsBaseline_${deployment().name}'

@description('Name of the custom iamge to create and distribute using Azure Image Builder.')
param runOutputName string = 'Win2019_AzureWindowsBaseline_CustomImage'

@description('List the regions in Azure where you would like to replicate the custom image after it is created.')
param replicationRegions array = [
  'canadacentral'
  'eastus2'
]

@description('A unique string generated for each deployment, to make sure the script is always run.')
param forceUpdateTag string = newGuid()

//var customizerScriptUri = uri('${GetSASToken.outputs.ContainerBlobEndpoint}${customizerScriptName}', '${GetSASToken.outputs.myContainerUploadSAS}')
var customizerScriptUri = '${GetSASToken.outputs.ContainerBlobEndpoint}${customizerScriptName}${GetSASToken.outputs.myContainerUploadSAS}'
var AIBIdentityRoleAssignmentName = guid(AIBIdentity.outputs.identityId, resourceGroup().id, AIBCustomRoleDefinition.outputs.AIBCustomRoleDefinitionId)
var AIBIdentityRoleAssignNametoSA = guid(AIBIdentity.outputs.identityId, resourceGroup().id)
var StorageBlobReaderRoleID = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'


// Fetch the SAS token for the storage account containing customization scripts. Can be module [maybe ? ]

module GetSASToken 'bicep-modules/get-sas-token.bicep' = {
  name: 'get-SAS-Token'
  params: {
    storageaccountName: storageaccountName
    storageaccountRG: storageaccountRG
    container: container
  }
}


// Module for AIB Custom role definition 
module AIBCustomRoleDefinition 'bicep-modules/aib-custom-role.bicep' = {
  name: 'deploy-AIBCustomRoleDefinition'
  params: {
    name: templateIdentityRoleDefinitionName
  }
}

// Module to create User Managed Identity for AIB
module AIBIdentity 'bicep-modules/user-assigned-identity.bicep' = {
  name: 'deploy-AIB-Identity'
  params: {
    name: templateIdentityName
  }
}

// Module for role assignment. AIB User assigned idenity to AIB RG
module AIBRoleAssignment 'bicep-modules/aib-role-assignment-to-sp.bicep' = {
  name: 'Grant-AIB-identity-access-to-RG'
  params: {
    templateIdentityRoleAssignmentName: AIBIdentityRoleAssignmentName
    scope: resourceGroup().id
    RoleDefinitionID: AIBCustomRoleDefinition.outputs.AIBCustomRoleDefinitionId
    PrincipalID: AIBIdentity.outputs.identityPrincipalId
  }
}

// Module to assign Storage Reader role for storage account for Customization script to AIB user managed identity

module AIBRoleAssignmentoStorage 'bicep-modules/aib-role-assignment-sa.bicep' = {
    name: 'Grant-AIB-identity-toCxSA'
    scope: resourceGroup(storageaccountRG)
    params:{
    templateIdentityRoleAssignmentName: AIBIdentityRoleAssignNametoSA
    storageaccountName: storageaccountName
    RoleDefinitionID: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', StorageBlobReaderRoleID)
    PrincipalID: AIBIdentity.outputs.identityPrincipalId
   }
}

//Module for Shared Image Gallery (SIG)
module sig 'bicep-modules/sig.bicep' = {
  name: 'deploy-Shared-Image-Gallery'
  params: {
    SIGName: imageGalleryName
    location: location
  }
}

// Module for Image definiition in SIG

module imageDefinition 'bicep-modules/imageDefinition.bicep' = {
  name: 'deploy-Image-definition'
  params: {
    SIGname: imageGalleryName
    location: location
    imageDefinitionProperties:imageDefinitionProperties
  }
  dependsOn: [
    sig
  ]
}

// Module for creating Image Template

module WindowsServer2019_AzureBaseline 'bicep-modules/images/WindowsServer2019-AzureBaseline.bicep' = {
  name: 'create-image-definition-WinServ2019'
  params: {
    imageTemplateName: imageTemplateName
    imageDefinitionID: imageDefinition.outputs.imageDefinitionID
    location: image_location
    AIBIdentityID: AIBIdentity.outputs.identityId
    customizerScriptUri: customizerScriptUri
    runOutputName: runOutputName
    replicationRegions: replicationRegions

  }
}

//Module for Image Build

module imageBuild 'bicep-modules/aib-image-build.bicep' = {
  name: 'build-image'
  params: {
    location: image_location
    AIBIdentity: AIBIdentity.outputs.identityId
    imageTemplateName: imageTemplateName
    forceUpdateTag: forceUpdateTag
  }
  dependsOn: [
    WindowsServer2019_AzureBaseline
    AIBRoleAssignment
  ]
}

output ImageTemplateName string = imageTemplateName
output ImageTemplateRG string = resourceGroup().name
