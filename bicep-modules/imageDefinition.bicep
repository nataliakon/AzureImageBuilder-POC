param imageDefinitionProperties object 
param location string
param SIGname string

var ImageDefinitionName = '${SIGname}/${imageDefinitionProperties.name}'


resource imageDefinition 'Microsoft.Compute/galleries/images@2020-09-30' = {
  name: ImageDefinitionName
  location: location
  properties: {
    osType: 'Windows'
    osState: 'Generalized'
    identifier: {
      publisher: imageDefinitionProperties.publisher
      offer: imageDefinitionProperties.offer
      sku: imageDefinitionProperties.sku
    }
    recommended: {
      vCPUs: {
        min: 2
        max: 8
      }
      memory: {
        min: 16
        max: 48
      }
    }
    hyperVGeneration: 'V1'
  }
}

output imageDefinitionID string = imageDefinition.id
