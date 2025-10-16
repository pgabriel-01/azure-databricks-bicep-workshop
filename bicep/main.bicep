// Bicep Azure Databricks Workshop - Modular Main Template
// This template demonstrates Infrastructure as Code best practices
// for deploying Azure Databricks workspace with supporting resources using modules

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
var commonTags = {
  Environment: environment
  Project: projectName
  Owner: owner
  CostCenter: costCenter
  DeployedBy: 'Bicep'
  DeploymentTime: deploymentTime
}

// Deploy networking infrastructure
module networking 'modules/networking.bicep' = {
  name: 'networking-deployment'
  params: {
    prefix: resourcePrefix
    location: location
    vnetAddressPrefix: '10.0.0.0/16'
    publicSubnetPrefix: '10.0.1.0/24'
    privateSubnetPrefix: '10.0.2.0/24'
    tags: commonTags
  }
}

// Deploy security infrastructure
module security 'modules/security.bicep' = {
  name: 'security-deployment'
  params: {
    prefix: resourcePrefix
    location: location
    environment: environment
    logRetentionDays: logRetentionDays
    keyVaultSku: keyVaultSku
    deploymentTimestamp: deploymentTime
    tags: commonTags
  }
}

// Deploy storage infrastructure
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    prefix: resourcePrefix
    location: location
    storageAccountTier: storageAccountTier
    storageReplicationType: storageReplicationType
    keyVaultId: security.outputs.keyVaultId
    tags: commonTags
  }
}

// Deploy Databricks workspace
module databricks 'modules/databricks.bicep' = {
  name: 'databricks-deployment'
  params: {
    prefix: resourcePrefix
    location: location
    databricksSku: databricksSku
    noPublicIp: noPublicIp
    vnetId: networking.outputs.vnetId
    publicSubnetName: networking.outputs.publicSubnetName
    privateSubnetName: networking.outputs.privateSubnetName
    tags: commonTags
  }
}

// Outputs - maintaining compatibility with existing parameter files
@description('URL of the Databricks workspace')
output databricksWorkspaceUrl string = databricks.outputs.workspaceUrl

@description('ID of the Databricks workspace')
output databricksWorkspaceId string = databricks.outputs.workspaceId

@description('Name of the storage account')
output storageAccountName string = storage.outputs.storageAccountName

@description('Primary blob endpoint of the storage account')
output storageAccountPrimaryEndpoint string = storage.outputs.storageAccountPrimaryEndpoint

@description('Names of the storage containers')
output storageContainers object = {
  raw: storage.outputs.rawDataContainerName
  processed: storage.outputs.processedDataContainerName
}

@description('Name of the Key Vault')
output keyVaultName string = security.outputs.keyVaultName

@description('URI of the Key Vault')
output keyVaultUri string = security.outputs.keyVaultUri

@description('Name of the virtual network')
output virtualNetworkName string = networking.outputs.vnetName

@description('ID of the virtual network')
output virtualNetworkId string = networking.outputs.vnetId

@description('Name of the Log Analytics workspace')
output logAnalyticsWorkspaceName string = security.outputs.logAnalyticsWorkspaceName

@description('ID of the Log Analytics workspace')
output logAnalyticsWorkspaceId string = security.outputs.logAnalyticsWorkspaceId

@description('Common resource tags')
output commonTags object = commonTags
