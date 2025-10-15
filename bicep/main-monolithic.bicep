// Bicep Azure Databricks Workshop - Main Template
// This template demonstrates Infrastructure as Code best practices
// for deploying Azure Databricks workspace with supporting resources

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Name of the project for resource naming')
@minLength(3)
@maxLength(20)
param projectName string = 'databricks-workshop'

@description('Owner of the resources for tagging purposes')
param owner string = 'workshop-participant'

@description('Cost center for billing and resource tracking')
param costCenter string = 'workshop'

@description('SKU for Azure Databricks workspace')
@allowed(['standard', 'premium', 'trial'])
param databricksSku string = 'standard'

@description('Enable no public IP for Databricks workspace')
param noPublicIp bool = false

@description('Storage account tier')
@allowed(['Standard', 'Premium'])
param storageAccountTier string = 'Standard'

@description('Storage replication type')
@allowed(['LRS', 'GRS', 'RAGRS', 'ZRS'])
param storageReplicationType string = 'LRS'

@description('Log Analytics workspace retention in days')
@minValue(30)
@maxValue(730)
param logRetentionDays int = 30

@description('Key Vault SKU')
@allowed(['standard', 'premium'])
param keyVaultSku string = 'standard'

@description('Deployment timestamp for tagging')
param deploymentTime string = utcNow('yyyy-MM-dd')

// Variables for consistent naming and resource configuration
var resourcePrefix = '${environment}-${projectName}'
var suffix = uniqueString(resourceGroup().id)

// Common tags applied to all resources
var commonTags = {
  Environment: environment
  Project: projectName
  ManagedBy: 'Bicep'
  Owner: owner
  CostCenter: costCenter
  CreatedDate: deploymentTime
  Repository: 'bicep-databricks-workshop'
}

// Resource naming with suffix
var databricksWorkspaceName = '${resourcePrefix}-dbw-${suffix}'
var storageAccountBase = replace('${resourcePrefix}sa${suffix}', '-', '')
var storageAccountName = length(storageAccountBase) > 24 ? take(storageAccountBase, 24) : (length(storageAccountBase) < 3 ? '${storageAccountBase}abc' : storageAccountBase)
var keyVaultName = take('${resourcePrefix}-kv-${suffix}', 24)
var virtualNetworkName = '${resourcePrefix}-vnet-${suffix}'
var logAnalyticsName = '${resourcePrefix}-law-${suffix}'

// Virtual Network for Databricks (VNet injection)
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: virtualNetworkName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'public-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'databricks-delegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
          networkSecurityGroup: {
            id: publicNsg.id
          }
        }
      }
      {
        name: 'private-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'databricks-delegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
          networkSecurityGroup: {
            id: privateNsg.id
          }
        }
      }
    ]
  }
}

// Network Security Group for public subnet
resource publicNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${resourcePrefix}-public-nsg-${suffix}'
  location: location
  tags: commonTags
  properties: {
    securityRules: []
  }
}

// Network Security Group for private subnet
resource privateNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${resourcePrefix}-private-nsg-${suffix}'
  location: location
  tags: commonTags
  properties: {
    securityRules: []
  }
}

// Log Analytics Workspace for monitoring
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logRetentionDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Storage Account for data storage
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: commonTags
  sku: {
    name: '${storageAccountTier}_${storageReplicationType}'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

// Enable blob versioning and configure retention policies
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    isVersioningEnabled: true
    changeFeed: {
      enabled: true
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// Storage container for raw data
resource rawDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobServices
  name: 'raw-data'
  properties: {
    publicAccess: 'None'
  }
}

// Storage container for processed data
resource processedDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobServices
  name: 'processed-data'
  properties: {
    publicAccess: 'None'
  }
}

// Key Vault for secrets management
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: commonTags
  properties: {
    enabledForDiskEncryption: true
    tenantId: subscription().tenantId
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false
    sku: {
      name: keyVaultSku
      family: 'A'
    }
    accessPolicies: []
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Store storage account connection string in Key Vault
resource storageConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'storage-connection-string'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'
  }
}

// Azure Databricks Workspace
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: databricksWorkspaceName
  location: location
  tags: commonTags
  sku: {
    name: databricksSku
  }
  properties: {
    managedResourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourcePrefix}-databricks-managed-rg-${suffix}'
    parameters: {
      customVirtualNetworkId: {
        value: virtualNetwork.id
      }
      customPrivateSubnetName: {
        value: 'private-subnet'
      }
      customPublicSubnetName: {
        value: 'public-subnet'
      }
      enableNoPublicIp: {
        value: noPublicIp
      }
    }
  }
}

// Outputs providing important information about deployed resources
@description('Name of the resource group')
output resourceGroupName string = resourceGroup().name

@description('Location of the resource group')
output resourceGroupLocation string = location

@description('Name of the Databricks workspace')
output databricksWorkspaceName string = databricksWorkspace.name

@description('URL of the Databricks workspace')
output databricksWorkspaceUrl string = databricksWorkspace.properties.workspaceUrl

@description('ID of the Databricks workspace')
output databricksWorkspaceId string = databricksWorkspace.properties.workspaceId

@description('Name of the storage account')
output storageAccountName string = storageAccount.name

@description('Primary blob endpoint of the storage account')
output storageAccountPrimaryEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Names of the storage containers')
output storageContainers object = {
  raw: rawDataContainer.name
  processed: processedDataContainer.name
}

@description('Name of the Key Vault')
output keyVaultName string = keyVault.name

@description('URI of the Key Vault')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Name of the virtual network')
output virtualNetworkName string = virtualNetwork.name

@description('ID of the virtual network')
output virtualNetworkId string = virtualNetwork.id

@description('Name of the Log Analytics workspace')
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name

@description('ID of the Log Analytics workspace')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('Common resource tags')
output commonTags object = commonTags
