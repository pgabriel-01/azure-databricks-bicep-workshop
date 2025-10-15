// Security Module - Key Vault, Log Analytics for Databricks
// This module creates security and monitoring infrastructure

@description('Resource prefix for naming')
param prefix string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Log Analytics workspace retention in days')
@minValue(30)
@maxValue(730)
param logRetentionDays int = 30

@description('Key Vault SKU')
@allowed(['standard', 'premium'])
param keyVaultSku string = 'standard'

@description('Environment name for access policies')
param environment string

@description('Resource tags')
param tags object = {}

// Log Analytics Workspace for monitoring
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${prefix}-law'
  location: location
  tags: tags
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

// Key Vault for storing secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: take('${prefix}kv${uniqueString(resourceGroup().id)}', 24)
  location: location
  tags: tags
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    sku: {
      name: keyVaultSku
      family: 'A'
    }
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    // Only enable purge protection for production environments
    // For dev/staging, omit this property (don't set to false)
    ...(environment == 'prod' ? { enablePurgeProtection: true } : {})
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    accessPolicies: []
  }
}

// Outputs
@description('Log Analytics workspace resource ID')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('Log Analytics workspace name')
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name

@description('Key Vault resource ID')
output keyVaultId string = keyVault.id

@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri
