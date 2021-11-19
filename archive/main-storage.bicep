@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param storageaccountName string
param container string

@description('Resource group of the storage account for customizer script')

param storageaccountRG string

//@description('The name of the customizer script which will be executed during image build.')
//param customizerScriptName string = 's/scripts/runScript.ps1?'



//var customizerScriptUri = uri('${GetSASToken.outputs.ContainerBlobEndpoint}${customizerScriptName}', '${GetSASToken.outputs.myContainerUploadSAS}')
//var AIBIdentityRoleAssignmentName = guid(AIBIdentity.outputs.identityId, resourceGroup().id, AIBCustomRoleDefinition.outputs.AIBCustomRoleDefinitionId)

// Fetch the SAS token for the storage account containing customization scripts. Can be module [maybe ? ]

module GetSASToken 'bicep-modules/get-sas-token.bicep' = {
  name: 'get-SAS-Token'
  params: {
    storageaccountName: storageaccountName
    storageaccountRG: storageaccountRG
    container: container
  }
}
