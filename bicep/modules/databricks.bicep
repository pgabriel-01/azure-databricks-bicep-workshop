// Databricks Module - Azure Databricks Workspace
// This module creates the Databricks workspace with VNet injection

@description('Resource prefix for naming')
param prefix string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('SKU for Azure Databricks workspace')
@allowed(['standard', 'premium', 'trial'])
param databricksSku string = 'standard'

@description('Enable no public IP for Databricks workspace')
param noPublicIp bool = false

@description('Virtual network resource ID')
param vnetId string

@description('Public subnet name')
param publicSubnetName string

@description('Private subnet name')
param privateSubnetName string

@description('Resource tags')
param tags object = {}

// Variables
var managedResourceGroupName = '${prefix}-managed-rg'

// Azure Databricks Workspace
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: '${prefix}-db'
  location: location
  tags: tags
  sku: {
    name: databricksSku
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroupName)
    parameters: !empty(vnetId) ? {
      customVirtualNetworkId: {
        value: vnetId
      }
      customPublicSubnetName: {
        value: publicSubnetName
      }
      customPrivateSubnetName: {
        value: privateSubnetName
      }
      enableNoPublicIp: {
        value: noPublicIp
      }
    } : {}
    publicNetworkAccess: 'Enabled'
    requiredNsgRules: 'AllRules'
  }
}

// Outputs
@description('Databricks workspace resource ID')
output workspaceId string = databricksWorkspace.id

@description('Databricks workspace name')
output workspaceName string = databricksWorkspace.name

@description('Databricks workspace URL')
output workspaceUrl string = databricksWorkspace.properties.workspaceUrl

@description('Managed resource group name')
output managedResourceGroupName string = managedResourceGroupName
