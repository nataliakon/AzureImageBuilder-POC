param SIGName string
param location string

resource imageGallery 'Microsoft.Compute/galleries@2020-09-30' = {
  name: SIGName
  location: location
  properties: {}
}
