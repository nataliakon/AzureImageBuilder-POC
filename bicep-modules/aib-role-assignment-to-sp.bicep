param templateIdentityRoleAssignmentName string
param RoleDefinitionID string
param PrincipalID string
param scope string


resource templateRoleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: templateIdentityRoleAssignmentName
  properties: {
    roleDefinitionId: RoleDefinitionID
    principalId: PrincipalID
    scope: scope
    principalType: 'ServicePrincipal'
  }
}
