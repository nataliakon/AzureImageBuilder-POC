param imageTemplateName string
param location string
param AIBIdentityID string
param FsLogixScriptUri string
param OptimizeOSScriptUri string
param InstallTeamsScriptUri string
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
    buildTimeoutInMinutes: 240
    vmProfile: {
      vmSize: 'Standard_D2_v3'
      osDiskSizeGB: 127
    }
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'Windows-10'
      sku: '21h1-evd'
      version: 'latest'
    }
    customize: [
      {
        type: 'PowerShell'
        name: 'InstallFsLogix'
        runElevated: true
        runAsSystem: true
        scriptUri: FsLogixScriptUri
      }

      {
        type: 'PowerShell'
        name: 'OptimizeOS'
        runElevated: true
        runAsSystem: true
        scriptUri: OptimizeOSScriptUri
      }

      {
        type: 'WindowsRestart'
        restartCheckCommand: 'write-host "restarting post Optimizations"'
        restartTimeout: '5m'

      }

       {
         type: 'PowerShell'
         name: 'Install_Teams'
         runAsSystem: true
         runElevated: true
         scriptUri: InstallTeamsScriptUri
       }  

        {
          type: 'WindowsRestart'
          restartCheckCommand: 'write-host "restarting post Teams install" '
          restartTimeout: '5m'
        }
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
          'exclude:$_.Title -like \'*Preview*\''
          'include:$true'
        ]
        updateLimit: 40
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
