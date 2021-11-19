param templateIdentityRoleAssignmentName string
param RoleDefinitionID string
param PrincipalID string
param storageaccountName string
//param storageaccountRG string


resource stg 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageaccountName
}

resource templateRoleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: templateIdentityRoleAssignmentName
  scope: stg
  properties: {
    roleDefinitionId: RoleDefinitionID
    principalId: PrincipalID
    principalType: 'ServicePrincipal'
  }
}
