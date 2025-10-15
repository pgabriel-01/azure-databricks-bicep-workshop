# Bicep vs Terraform Comparison

This directory contains equivalent Infrastructure as Code implementations for deploying Azure Databricks infrastructure using both **Bicep** and **Terraform**. This comparison demonstrates the differences between the two approaches and helps understand when to use each tool.

## Directory Structure

```
bicep-comparison/
├── main.bicep              # Bicep implementation
├── README.md              # This file
└── ...

terraform-comparison/
├── main.tf                # Main Terraform configuration
├── variables.tf           # Variable definitions
├── outputs.tf             # Output definitions
├── terraform.tfvars.example  # Example variable values
└── modules/               # Modular components
    ├── networking/        # VNet, subnets, NSGs
    ├── security/          # Key Vault, Log Analytics
    ├── storage/           # Storage Account, containers
    └── databricks/        # Databricks workspace
```

## Infrastructure Components

Both implementations deploy the same Azure resources:

- **Networking**: Virtual Network with Databricks-delegated subnets
- **Security**: Key Vault for secrets, Log Analytics for monitoring
- **Storage**: Data Lake Gen2 storage account with containers
- **Databricks**: Azure Databricks workspace with VNet injection

## Key Differences

### **Syntax and Readability**

#### Bicep (Declarative, TypeScript-inspired)
```bicep
@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
  }
}
```

#### Terraform (HashiCorp Configuration Language)
```terraform
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}
```

### **State Management**

| Aspect | Bicep | Terraform |
|--------|-------|-----------|
| **State Storage** | Azure manages state automatically | Requires explicit state management |
| **State Backend** | No configuration needed | Must configure backend (Azure Storage, etc.) |
| **State Locking** | Built-in | Requires configuration |
| **Team Collaboration** | Automatic | Requires shared state setup |

### **Type Safety and Validation**

| Feature | Bicep | Terraform |
|---------|-------|-----------|
| **Compile-time validation** | Yes - Built-in | Warning - Plan-time only |
| **IntelliSense support** | Yes - Excellent | Yes - Good |
| **Parameter validation** | Yes - `@allowed`, `@minValue` decorators | Yes - Validation blocks |
| **Resource API validation** | Yes - Latest APIs always | Warning - Provider-dependent |

### **Deployment and Planning**

#### Bicep What-If Analysis
```bash
az deployment group what-if \
  --resource-group "rg-databricks-dev" \
  --template-file main.bicep \
  --parameters dev.bicepparam
```

#### Terraform Plan
```bash
terraform plan -var-file="dev.tfvars"
```

### **Modularity**

#### Bicep Modules
```bicep
module networking 'modules/networking.bicep' = {
  name: 'networking-deployment'
  params: {
    prefix: resourcePrefix
    location: location
    tags: commonTags
  }
}
```

#### Terraform Modules
```terraform
module "networking" {
  source = "./modules/networking"

  resource_prefix = local.resource_prefix
  location       = var.location
  tags           = local.common_tags
}
```

## Comparison Matrix

| Criteria | Bicep | Terraform | Winner |
|----------|-------|-----------|--------|
| **Azure Native** | Yes - Built for Azure | Warning - Multi-cloud focus | Bicep |
| **Learning Curve** | Yes - Easier for Azure | Warning - Steeper | Bicep |
| **State Management** | Yes - Automatic | No - Manual setup | Bicep |
| **Multi-cloud** | No - Azure only | Yes - Excellent | Terraform |
| **Community/Ecosystem** | Warning - Growing | Yes - Mature | Terraform |
| **Provider Updates** | Yes - Always current | Warning - Lag time | Bicep |
| **IDE Support** | Yes - Excellent VS Code | Yes - Good | Tie |
| **Template Portability** | No - Azure only | Yes - Multi-cloud | Terraform |

## Getting Started

### **Bicep Deployment**
```bash
# Navigate to bicep directory
cd ../bicep

# Validate template
az bicep build --file main.bicep

# Deploy
az deployment group create \
  --resource-group "rg-databricks-dev" \
  --template-file main.bicep \
  --parameters parameters/dev.bicepparam
```

### **Terraform Deployment**
```bash
# Navigate to terraform directory
cd terraform-comparison

# Copy example variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply
```

## Workshop Usage

### **For Learning Bicep**
- Start with the Bicep implementation
- Focus on Azure-specific features
- Leverage IntelliSense and validation
- Use what-if analysis for safety

### **For Learning Terraform**
- Begin with the Terraform implementation
- Understand state management concepts
- Practice with modules and variables
- Learn plan/apply workflow

### **For Comparison**
- Deploy the same infrastructure with both tools
- Compare the syntax and structure
- Evaluate deployment speed and experience
- Consider maintenance and team collaboration aspects

## When to Choose Which

### **Choose Bicep When:**
- Working exclusively with Azure
- Team is new to Infrastructure as Code
- Want automatic state management
- Need always-current Azure APIs
- Prefer declarative, clean syntax

### **Choose Terraform When:**
- Multi-cloud or hybrid deployment
- Existing Terraform expertise/infrastructure
- Need advanced provisioning features
- Require complex conditional logic
- Working with non-Azure resources

## Next Steps

1. **Try Both**: Deploy infrastructure with both tools
2. **Compare Results**: Examine deployed resources
3. **Evaluate Workflow**: Consider which fits your team better
4. **Make Decision**: Choose based on your specific needs

## Additional Resources

- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)
- [Bicep vs ARM vs Terraform Comparison](https://docs.microsoft.com/azure/azure-resource-manager/bicep/compare-template-syntax)

---

**Note**: Both implementations produce identical Azure infrastructure. The choice between them depends on your team's needs, existing expertise, and future requirements.