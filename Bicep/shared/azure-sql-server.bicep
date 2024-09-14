import { AzureSqlDatabaseSettings } from 'types-and-vars.bicep'

param sqlServerName string
param sqlLoginName string
@secure()
param sqlLoginPassword string
param subnetId string
param sqlServerVnetRulesName string
param listOfSqlDatabaseSettings AzureSqlDatabaseSettings[]

var location = resourceGroup().location

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    displayName: 'SqlServer'
  }
  properties: {
    administratorLogin: sqlLoginName
    administratorLoginPassword: sqlLoginPassword
    version: '12.0'
  }
}

resource vnetRules 'Microsoft.Sql/servers/virtualNetworkRules@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlServerVnetRulesName
  //location: location
  properties: {
    virtualNetworkSubnetId: subnetId
  }
}

resource sqlDatabases 'Microsoft.Sql/servers/databases@2022-05-01-preview' = [for settings in listOfSqlDatabaseSettings: {
  parent: sqlServer
  name: settings.name
  location: location
  tags: {
    displayName: settings.name
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: settings.maxSizeBytes
    edition: split(settings.serviceTier, '_')[0]
    requestedServiceObjectiveName: split(settings.serviceTier, '_')[1]
  }
}]

output fqdn string = sqlServer.properties.fullyQualifiedDomainName
