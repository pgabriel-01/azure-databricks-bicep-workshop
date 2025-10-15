# Terraform vs Bicep Comparison

This document compares the implementation of the same Azure Databricks infrastructure using both Terraform and Bicep, highlighting the key differences and best practices for each tool.

## Overview

Both implementations create identical Azure infrastructure:
- Azure Databricks Workspace with VNet injection
- Virtual Network with public and private subnets
- Network Security Groups
- Storage Account with containers
- Key Vault for secrets management
- Log Analytics Workspace for monitoring

## Key Differences

### 1. Syntax and Language

**Terraform (HCL)**
```hcl
resource "azurerm_databricks_workspace" "main" {
  name                        = local.databricks_workspace
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                        = var.databricks_sku
  managed_resource_group_name = "${local.resource_prefix}-databricks-managed-rg-${random_string.suffix.result}"

  custom_parameters {
    no_public_ip                                         = var.no_public_ip
    virtual_network_id                                   = azurerm_virtual_network.main.id
    private_subnet_name                                  = azurerm_subnet.private.name
    public_subnet_name                                   = azurerm_subnet.public.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
  }

  tags = local.common_tags
}
```

**Bicep**
```bicep
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
```

### 2. Variable Definitions

**Terraform**
```hcl
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
```

**Bicep**
```bicep
@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'
```

### 3. State Management

**Terraform**
- External state file (local or remote backend)
- Explicit state management with `terraform.tfstate`
- Supports state locking with Azure Storage backend
- State drift detection with `terraform plan`

**Bicep**
- No explicit state file - Azure Resource Manager tracks deployment state
- Built-in state management through ARM deployment history
- Automatic drift detection through Azure portal
- Declarative approach - ARM ensures desired state

### 4. Provider Configuration

**Terraform**
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.30"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
```

**Bicep**
- No explicit provider configuration needed
- Uses Azure Resource Manager natively
- API versions specified directly in resource definitions
- Built-in Azure integration

### 5. Random Values and Uniqueness

**Terraform**
```hcl
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
```

**Bicep**
```bicep
var suffix = uniqueString(resourceGroup().id)
```

### 6. Conditional Logic

**Terraform**
```hcl
dynamic "custom_parameters" {
  for_each = var.enable_vnet_injection ? [1] : []
  content {
    no_public_ip = var.no_public_ip
    virtual_network_id = var.virtual_network_id
  }
}
```

**Bicep**
```bicep
parameters: var.enable_vnet_injection ? {
  customVirtualNetworkId: {
    value: virtualNetwork.id
  }
  enableNoPublicIp: {
    value: noPublicIp
  }
} : {}
```

## Advantages and Disadvantages

### Terraform

**Advantages:**
- Multi-cloud support (AWS, GCP, Azure, etc.)
- Mature ecosystem with many providers
- Strong community and third-party modules
- Explicit state management and planning
- Advanced features like workspaces and remote backends
- Rich CLI with detailed output

**Disadvantages:**
- Learning curve for HCL syntax
- State file management complexity
- Provider dependencies and version management
- Potential state drift issues
- Requires external state storage for teams

**Best Practices:**
- Use remote state storage (Azure Storage)
- Implement state locking
- Use modules for reusability
- Follow naming conventions
- Implement proper tagging strategy
- Use workspaces for environment separation

### Bicep

**Advantages:**
- Native Azure integration
- No state file management
- Strong typing and IntelliSense support
- Compiled to ARM templates
- Built-in Azure functions and references
- Simpler syntax for Azure-specific scenarios

**Disadvantages:**
- Azure-only (not multi-cloud)
- Less mature ecosystem
- Limited compared to Terraform's feature set
- ARM template limitations apply
- Smaller community

**Best Practices:**
- Use parameters for environment-specific values
- Leverage built-in functions like `uniqueString()`
- Implement proper resource naming conventions
- Use symbolic names for resource references
- Apply consistent tagging strategy

## When to Choose Which

### Choose Terraform When:
- Multi-cloud strategy is required
- Team has existing Terraform expertise
- Complex state management requirements
- Need for advanced features like workspaces
- Using multiple providers beyond Azure
- Mature CI/CD pipeline requirements

### Choose Bicep When:
- Azure-only infrastructure
- Team prefers native Azure tooling
- Simple to moderate complexity deployments
- Want tight Azure integration
- Prefer declarative ARM-style templates
- New to Infrastructure as Code

## Cost Considerations

Both tools are free to use, but consider:

**Terraform:**
- Potential costs for Terraform Cloud/Enterprise
- Storage costs for remote state
- Learning and training investment

**Bicep:**
- No additional tooling costs
- Leverages existing ARM deployment tracking
- Lower learning curve for Azure-focused teams

## Security Best Practices

### Common to Both:
- Use Azure Key Vault for secrets
- Implement least privilege access
- Enable logging and monitoring
- Use managed identities where possible
- Regular security reviews

### Terraform-Specific:
- Secure state file storage
- State file encryption
- Backend authentication
- Sensitive value handling

### Bicep-Specific:
- Parameter file security
- ARM deployment permissions
- Resource-level RBAC

## Conclusion

Both Terraform and Bicep are excellent Infrastructure as Code tools for Azure. The choice depends on:

1. **Scope**: Multi-cloud (Terraform) vs Azure-only (Bicep)
2. **Team expertise**: Existing skills and preferences
3. **Complexity**: Simple deployments favor Bicep, complex scenarios favor Terraform
4. **Integration**: Native Azure integration (Bicep) vs flexible ecosystem (Terraform)

For this workshop, we've demonstrated both approaches to give you hands-on experience with each tool, enabling you to make informed decisions for your specific use cases.