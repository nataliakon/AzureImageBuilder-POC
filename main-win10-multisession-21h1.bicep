@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param storageaccountName string
param container string

@description('Resource group of the storage account for customizer script')

param storageaccountRG string


@description('The Azure region where resources in the template should be deployed.')
param location string = resourceGroup().location

@description('location for image definition')
param image_location string = 'eastus2'

@description('The name of the FSLogix script which will be executed during image build.')
param FsLogixScriptName string = '/s/scripts/AVD/0_installConfFsLogix.ps1?'

@description('The name of the Optimize script  for AVD which will be executed during image build.')
param OptimizeOSScriptName string = '/s/scripts/AVD/1_Optimize_OS_for_WVD.ps1?'

@description('The name of the Install Teams script which will be executed during image build.')
param InstallTeamsScriptName string = '/s/scripts/AVD/2_installTeams.ps1?'

@description('Name of the user-assigned managed identity used by Azure Image Builder template, and for triggering the Azure Image Builder build at the end of the deployment')
param templateIdentityName string = substring('ImageGallery_${guid(resourceGroup().id)}', 0, 21)

@description('Permissions to allow for the user-assigned managed identity.')
param templateIdentityRoleDefinitionName string = guid(resourceGroup().id)

@description('Name of the new Azure Image Gallery resource.')
param imageGalleryName string = substring('ImageGallery_${guid(resourceGroup().id)}', 0, 21)

@description('Detailed image information to set for the custom image produced by the Azure Image Builder build.')
param imageDefinitionProperties object = {
  name: 'Win10_Ent_Multisession_AVD_Optimized'
  publisher: 'AVDBaseline'
  offer: 'Windows-10'
  sku: '21h1-evd'
}

@description('Name of the template to create in Azure Image Builder.')
param imageTemplateName string = 'Win10MultiSession_AVD_${deployment().name}'

@description('Name of the custom iamge to create and distribute using Azure Image Builder.')
param runOutputName string = 'Win10MultiSession_AVD_CustomImage'

@description('List the regions in Azure where you would like to replicate the custom image after it is created.')
param replicationRegions array = [
  'canadacentral'
  'eastus2'
]

@description('A unique string generated for each deployment, to make sure the script is always run.')
param forceUpdateTag string = newGuid()

//var customizerScriptUri = uri('${GetSASToken.outputs.ContainerBlobEndpoint}${customizerScriptName}', '${GetSASToken.outputs.myContainerUploadSAS}')
var FsLogixScriptUri = '${GetSASToken.outputs.ContainerBlobEndpoint}${FsLogixScriptName}${GetSASToken.outputs.myContainerUploadSAS}'
var OptimizeOSScriptUri = '${GetSASToken.outputs.ContainerBlobEndpoint}${OptimizeOSScriptName}${GetSASToken.outputs.myContainerUploadSAS}'
var InstallTeamsScriptUri = '${GetSASToken.outputs.ContainerBlobEndpoint}${InstallTeamsScriptName}${GetSASToken.outputs.myContainerUploadSAS}'
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

module Windows10_AVDBaseline 'bicep-modules/images/Win10MultiSession_21H1_optimized_AVD.bicep' = {
  name: 'create-image-definition-Win10'
  params: {
    imageTemplateName: imageTemplateName
    imageDefinitionID: imageDefinition.outputs.imageDefinitionID
    location: image_location
    AIBIdentityID: AIBIdentity.outputs.identityId
    FsLogixScriptUri: FsLogixScriptUri
    OptimizeOSScriptUri: OptimizeOSScriptUri
    InstallTeamsScriptUri: InstallTeamsScriptUri
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
    Windows10_AVDBaseline
    AIBRoleAssignment
  ]
}

output ImageTemplateName string = imageTemplateName
output ImageTemplateRG string = resourceGroup().name
