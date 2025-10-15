// Networking Module - VNet, Subnets, NSGs for Databricks
// This module creates the network foundation for Azure Databricks with VNet injection

@description('Resource prefix for naming')
param prefix string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Virtual network address space')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Public subnet address prefix')
param publicSubnetPrefix string = '10.0.1.0/24'

@description('Private subnet address prefix')
param privateSubnetPrefix string = '10.0.2.0/24'

@description('Resource tags')
param tags object = {}

// Virtual Network with Databricks-specific configuration
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${prefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: 'public-subnet'
        properties: {
          addressPrefix: publicSubnetPrefix
          networkSecurityGroup: {
            id: publicNsg.id
          }
          delegations: [
            {
              name: 'databricks-delegation-public'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      {
        name: 'private-subnet'
        properties: {
          addressPrefix: privateSubnetPrefix
          networkSecurityGroup: {
            id: privateNsg.id
          }
          delegations: [
            {
              name: 'databricks-delegation-private'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
    ]
  }
}

// Network Security Group for Public Subnet
resource publicNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${prefix}-nsg-public'
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

// Network Security Group for Private Subnet
resource privateNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${prefix}-nsg-private'
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

// Outputs
@description('Virtual network resource ID')
output vnetId string = virtualNetwork.id

@description('Virtual network name')
output vnetName string = virtualNetwork.name

@description('Public subnet resource ID')
output publicSubnetId string = '${virtualNetwork.id}/subnets/public-subnet'

@description('Private subnet resource ID')
output privateSubnetId string = '${virtualNetwork.id}/subnets/private-subnet'

@description('Public subnet name')
output publicSubnetName string = 'public-subnet'

@description('Private subnet name')
output privateSubnetName string = 'private-subnet'

@description('Public NSG resource ID')
output publicNsgId string = publicNsg.id

@description('Private NSG resource ID')
output privateNsgId string = privateNsg.id
