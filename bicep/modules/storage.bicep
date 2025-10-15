// Storage Module - Data Lake Storage for Databricks
// This module creates storage infrastructure for data processing

@description('Resource prefix for naming')
param prefix string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Storage account tier')
@allowed(['Standard', 'Premium'])
param storageAccountTier string = 'Standard'

@description('Storage replication type')
@allowed(['LRS', 'GRS', 'RAGRS', 'ZRS'])
param storageReplicationType string = 'LRS'

@description('Key Vault resource ID for secrets')
param keyVaultId string

@description('Resource tags')
param tags object = {}

// Variables for storage account naming
var storageAccountNameBase = replace(prefix, '-', '')
var storageAccountName = take('${storageAccountNameBase}sa${uniqueString(resourceGroup().id)}', 24)

// Storage Account with Data Lake Gen2 capabilities
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: length(storageAccountName) >= 3 ? storageAccountName : 'dataworkshop${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: '${storageAccountTier}_${storageReplicationType}'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true // Enable hierarchical namespace for Data Lake
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// Blob Services configuration
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    changeFeed: {
      enabled: true
      retentionInDays: 7
    }
    // Note: Versioning is not supported with Data Lake Gen2 (hierarchical namespace)
    // isVersioningEnabled: false (omitted as it's not compatible with isHnsEnabled: true)
  }
}

// Raw data container
resource rawDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobServices
  name: 'raw-data'
  properties: {
    publicAccess: 'None'
  }
}

// Processed data container
resource processedDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobServices
  name: 'processed-data'
  properties: {
    publicAccess: 'None'
  }
}

// Store storage connection string in Key Vault
resource storageConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${last(split(keyVaultId, '/'))}/storage-connection-string'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
}

// Outputs
@description('Storage account resource ID')
output storageAccountId string = storageAccount.id

@description('Storage account name')
output storageAccountName string = storageAccount.name

@description('Storage account primary endpoint')
output storageAccountPrimaryEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Raw data container name')
output rawDataContainerName string = rawDataContainer.name

@description('Processed data container name')
output processedDataContainerName string = processedDataContainer.name

@description('Storage connection string secret name')
output storageConnectionStringSecretName string = storageConnectionStringSecret.name
