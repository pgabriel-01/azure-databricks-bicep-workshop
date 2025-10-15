// Bicep Template for Azure Databricks Workshop
// This template demonstrates the same infrastructure as the Terraform version
// Compare this with terraform/main.tf to understand the differences

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Name of the project for resource naming')
param projectName string = 'databricks-workshop'

@description('Owner of the resources for tagging purposes')
param owner string = 'workshop-participant'

@description('Cost center for billing and resource tracking')
param costCenter string = 'workshop'

@description('SKU for Azure Databricks workspace')
@allowed(['standard', 'premium', 'trial'])
param databricksSku string = 'standard'

@description('Whether to disable public IP for Databricks clusters')
param noPublicIp bool = false

@description('Number of days to retain logs in Log Analytics')
@minValue(30)
@maxValue(730)
param logRetentionDays int = 30

@description('Storage account performance tier')
@allowed(['Standard', 'Premium'])
param storageAccountTier string = 'Standard'

@description('Storage account replication type')
@allowed(['LRS', 'GRS', 'RAGRS', 'ZRS', 'GZRS', 'RAGZRS'])
param storageReplicationType string = 'LRS'

@description('SKU for Azure Key Vault')
@allowed(['standard', 'premium'])
param keyVaultSku string = 'standard'

// Variables for consistent naming
var resourcePrefix = '${environment}-${projectName}'
var suffix = uniqueString(resourceGroup().id)

// Common tags
var commonTags = {
  Environment: environment
  Project: projectName
  ManagedBy: 'Bicep'
  Owner: owner
  CostCenter: costCenter
  Repository: 'terraform-databricks-workshop'
}

// Resource names
var resourceNames = {
  databricksWorkspace: '${resourcePrefix}-dbw-${suffix}'
  storageAccount: replace('${resourcePrefix}sa${suffix}', '-', '')
  keyVault: '${resourcePrefix}-kv-${suffix}'
  virtualNetwork: '${resourcePrefix}-vnet-${suffix}'
  logAnalytics: '${resourcePrefix}-law-${suffix}'
  publicNsg: '${resourcePrefix}-public-nsg-${suffix}'
  privateNsg: '${resourcePrefix}-private-nsg-${suffix}'
}

// Virtual Network for Databricks (VNet injection)
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: resourceNames.virtualNetwork
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

// Network Security Groups
resource publicNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: resourceNames.publicNsg
  location: location
  tags: commonTags
  properties: {
    securityRules: []
  }
}

resource privateNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: resourceNames.privateNsg
  location: location
  tags: commonTags
  properties: {
    securityRules: []
  }
}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: resourceNames.logAnalytics
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

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: resourceNames.storageAccount
  location: location
  tags: commonTags
  sku: {
    name: '${storageAccountTier}_${storageReplicationType}'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Allow'
    }
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Storage Containers
resource rawDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/raw-data'
  properties: {
    publicAccess: 'None'
  }
}

resource processedDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/processed-data'
  properties: {
    publicAccess: 'None'
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: resourceNames.keyVault
  location: location
  tags: commonTags
  properties: {
    sku: {
      family: 'A'
      name: keyVaultSku
    }
    tenantId: tenant().tenantId
    enabledForDiskEncryption: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: 'YOUR_OBJECT_ID_HERE' // Replace with actual object ID
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'purge'
            'recover'
          ]
        }
      }
    ]
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Store storage connection string in Key Vault
resource storageConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'storage-connection-string'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'
  }
}

// Azure Databricks Workspace
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: resourceNames.databricksWorkspace
  location: location
  tags: commonTags
  sku: {
    name: databricksSku
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', '${resourcePrefix}-databricks-managed-rg-${suffix}')
    parameters: {
      customVirtualNetworkId: {
        value: virtualNetwork.id
      }
      customPublicSubnetName: {
        value: 'public-subnet'
      }
      customPrivateSubnetName: {
        value: 'private-subnet'
      }
      enableNoPublicIp: {
        value: noPublicIp
      }
    }
  }
}

// Outputs
output resourceGroupName string = resourceGroup().name
output resourceGroupLocation string = location
output databricksWorkspaceName string = databricksWorkspace.name
output databricksWorkspaceUrl string = databricksWorkspace.properties.workspaceUrl
output databricksWorkspaceId string = databricksWorkspace.properties.workspaceId
output storageAccountName string = storageAccount.name
output storageAccountPrimaryEndpoint string = storageAccount.properties.primaryEndpoints.blob
output storageContainers object = {
  raw: 'raw-data'
  processed: 'processed-data'
}
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output virtualNetworkName string = virtualNetwork.name
output virtualNetworkId string = virtualNetwork.id
output subnetNames object = {
  public: 'public-subnet'
  private: 'private-subnet'
}
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.properties.customerId
output commonTags object = commonTags

// Azure Portal links
output azurePortalLinks object = {
  resourceGroup: 'https://portal.azure.com/#@/resource/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}'
  databricks: 'https://portal.azure.com/#@/resource${databricksWorkspace.id}'
  storage: 'https://portal.azure.com/#@/resource${storageAccount.id}'
  keyVault: 'https://portal.azure.com/#@/resource${keyVault.id}'
}