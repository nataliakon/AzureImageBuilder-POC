param imageTemplateName string
param location string
param AIBIdentityID string
param customizerScriptUri string
param imageDefinitionID string
param runOutputName string
param replicationRegions array

resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' = {
  name: imageTemplateName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${AIBIdentityID}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 60
    vmProfile: {
      vmSize: 'Standard_D2_v3'
      osDiskSizeGB: 127
    }
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'
    }
    customize: [
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
          'exclude:$_.Title -like \'*Preview*\''
          'include:$true'
        ]
        updateLimit: 40
      }
      {
        type: 'PowerShell'
        name: 'AzureWindowsBaseline'
        runElevated: true
        scriptUri: customizerScriptUri
      }
    ]
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: imageDefinitionID
        runOutputName: runOutputName
        replicationRegions: replicationRegions
      }
    ]
  }
}

output ImageTemplateName string = imageTemplate.name
