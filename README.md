# Azure Databricks Bicep Workshop

A comprehensive workshop demonstrating Infrastructure as Code best practices with Azure Bicep and Databricks, featuring CI/CD pipelines, security implementations, and a complete comparison with Terraform.

> **Workshop Ready**: Version 1.1.5+ features enhanced global naming for reliable multi-participant deployments and cross-subscription compatibility.

## Workshop Objectives

By the end of this workshop, you will be able to:

1. **Infrastructure as Code**: Deploy Azure Databricks infrastructure using Bicep with best practices
2. **Data Engineering**: Build data processing pipelines in Azure Databricks
3. **CI/CD Implementation**: Automate infrastructure deployment and data pipeline management
4. **Security & Governance**: Implement proper security controls and monitoring
5. **Tool Comparison**: Understand when to use Bicep vs Terraform for Azure deployments

## Prerequisites

### Required Tools
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) (latest version)
- [Git](https://git-scm.com/downloads)
- [VS Code](https://code.visualstudio.com/) with extensions:
  - Bicep
  - Azure Resource Manager Tools
  - Azure Account
  - Python

### Azure Requirements
- Azure subscription with contributor access
- Azure AD permissions to create App Registrations
- Resource group creation permissions

### Knowledge Prerequisites
- Basic understanding of cloud computing concepts
- Familiarity with Azure services
- Basic Git knowledge
- Python programming basics

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── bicep.yml               # CI/CD pipeline with deploy/destroy
├── bicep/
│   ├── main.bicep                  # Main modular Bicep template
│   ├── parameters/                 # Environment-specific parameter files
│   │   ├── dev.bicepparam         # Development parameters
│   │   ├── staging.bicepparam     # Staging parameters
│   │   └── prod.bicepparam        # Production parameters
│   └── modules/                    # Modular Bicep templates
│       ├── networking.bicep        # Virtual network and subnets
│       ├── security.bicep          # Key Vault and Log Analytics
│       ├── storage.bicep           # Storage account with Data Lake Gen2
│       └── databricks.bicep        # Databricks workspace with VNet injection
├── terraform-comparison/          # Equivalent Terraform implementation
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Variable definitions
│   ├── outputs.tf                 # Output definitions
│   └── modules/                   # Terraform modules (networking, security, etc.)
├── databricks/
│   ├── notebooks/                 # Sample Databricks notebooks
│   └── jobs/                      # Job configurations
├── docs/                          # Comprehensive workshop documentation
│   ├── github-setup-guide.md     # Complete setup instructions
│   ├── authentication-setup.md   # Azure OIDC authentication guide
│   ├── modular-architecture.md   # Architecture overview
│   ├── troubleshooting.md        # Common issues and solutions
│   └── validation-checklist.md   # Pre-workshop validation
├── datasets/                      # Sample datasets for workshop
├── scripts/                       # Utility scripts
└── BICEP_VS_TERRAFORM_COMPLETE.md # Comprehensive tool comparison
```

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/pgabriel-01/azure-databricks-bicep-workshop.git
cd azure-databricks-bicep-workshop
```

### 2. Set Up Azure Authentication

Follow the comprehensive [GitHub Setup Guide](docs/github-setup-guide.md) to configure Azure OIDC authentication for passwordless CI/CD.

**Quick Setup Summary:**
1. Create Azure App Registration with federated credentials
2. Configure GitHub repository variables:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID` 
   - `AZURE_SUBSCRIPTION_ID`
3. Test authentication with GitHub Actions

**Manual Alternative:**
```bash
# Login to Azure
az login

# Get subscription info
az account show

# Set up federated identity credentials (see setup guide for details)
az ad app create --display-name "Databricks-Workshop-OIDC"
```

### 3. Verify Authentication Setup

After setting up OIDC, verify your GitHub repository has these variables:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID` 
- `AZURE_SUBSCRIPTION_ID`

### 4. Deploy Infrastructure

**Option 1: Using GitHub Actions (Recommended)**
1. Go to your repository's Actions tab
2. Select "Bicep Azure Databricks CI/CD" workflow
3. Click "Run workflow"
4. Choose environment (dev/staging/prod)
5. Leave "Destroy infrastructure" unchecked
6. Click "Run workflow"

**Option 2: Manual Deployment**
```bash
# Deploy to development environment
az group create --name "rg-databricks-dev" --location "East US"

az deployment group create \
  --resource-group "rg-databricks-dev" \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/dev.bicepparam

# Get deployment outputs
az deployment group show \
  --resource-group "rg-databricks-dev" \
  --name "main" \
  --query properties.outputs
```

### 5. Access Your Databricks Workspace

After deployment, get the workspace URL from the outputs:

```bash
az deployment group show \
  --resource-group "rg-databricks-dev" \
  --name "main" \
  --query properties.outputs.databricksWorkspaceUrl.value
```

### 6. Clean Up Resources

**Important: Always clean up resources after the workshop to avoid ongoing costs!**

**Option 1: Using GitHub Actions (Recommended)**
1. Go to your repository's Actions tab
2. Select "Bicep Azure Databricks CI/CD" workflow
3. Click "Run workflow"
4. Choose the same environment you deployed to
5. **Check "Destroy infrastructure"**
6. Click "Run workflow"

**Option 2: Manual Cleanup**
```bash
# Delete the entire resource group (removes all resources)
az group delete --name "rg-databricks-dev" --yes

# Verify deletion
az group exists --name "rg-databricks-dev"
```

For detailed cleanup instructions, see the [Troubleshooting Guide](docs/troubleshooting.md).

## Workshop Modules

### Module 1: Infrastructure as Code Fundamentals (90 minutes)
- Introduction to IaC concepts and benefits
- Bicep vs Terraform comparison
- Azure resource management overview
- **Hands-on**: Deploy basic infrastructure

### Module 2: Bicep Best Practices (75 minutes)
- Project structure and organization
- Parameter files and modularity
- User-defined types and validation
- Security considerations
- **Hands-on**: Refactor code using modules

### Module 3: Azure Databricks Deployment (90 minutes)
- Databricks architecture overview
- VNet injection and networking
- Security and RBAC configuration
- **Hands-on**: Deploy Databricks with Bicep

### Module 4: Data Pipeline Development (90 minutes)
- Databricks notebooks and jobs
- Data ingestion patterns
- Delta Lake implementation
- **Hands-on**: Build NYC taxi data pipeline

### Module 5: CI/CD Implementation (90 minutes)
- GitHub Actions for Bicep with OIDC authentication
- Infrastructure testing strategies
- Automated deployments and cleanup
- **Hands-on**: Set up complete CI/CD pipeline with destroy functionality

## Sample Dataset

This workshop uses the **NYC Taxi Trip Data** - a publicly available dataset perfect for demonstrating:
- Data ingestion and cleaning
- ETL pipeline development
- Analytics and machine learning
- Performance optimization

The dataset includes:
- Trip duration and distance
- Pickup and dropoff locations
- Fare information
- Payment methods

## Security Best Practices

### Infrastructure Security
- Use Azure Key Vault for secrets management
- Implement network security groups
- Enable VNet injection for Databricks
- Apply least privilege access principles

### Code Security
- Store sensitive values in Azure Key Vault
- Use managed identities where possible
- Implement proper RBAC
- Regular security scanning with Trivy

### CI/CD Security
- Use GitHub secrets for sensitive data
- Implement approval workflows for production
- Scan infrastructure code for vulnerabilities
- Audit all deployments

## Bicep Best Practices Demonstrated

### Project Organization
- **Global Naming Strategy**: Enhanced uniqueness using subscription + resource group + deployment identifiers
- **Workshop-Safe Naming**: Prevents conflicts in multi-participant environments
- **Consistent naming conventions** across all Azure resources
- Environment-specific parameter files
- Reusable modules
- Proper tagging strategy

### Modular Architecture
- Separate modules for networking, security, storage, and Databricks
- **Cross-subscription reliability** with enhanced resource naming
- Parameter validation with decorators
- Output management
- Resource dependencies

### Code Quality
- Input validation with `@allowed`, `@minValue`, `@maxValue`
- Comprehensive output documentation
- Clear resource dependencies
- Error handling and validation

### Security
- Secret management with Azure Key Vault
- Least privilege access with RBAC
- Network isolation with VNet injection
- Encryption at rest and in transit
- Least privilege access
- Network isolation
- Encryption at rest and in transit

## Troubleshooting

### Common Issues

**Azure Authentication Errors**
```bash
# Verify Azure CLI login
az account show

# Check service principal permissions
az role assignment list --assignee YOUR_CLIENT_ID
```

**Databricks Workspace Access**
- Ensure proper RBAC assignments
- Check network connectivity
- Verify workspace is in running state

**Bicep Deployment Issues**
```bash
# Validate Bicep template
az bicep build --file bicep/main.bicep

# Check resource group exists
az group show --name "rg-databricks-dev"

# View deployment details
az deployment group show --resource-group "rg-databricks-dev" --name "main"
```

### Getting Help
- Check the [troubleshooting guide](docs/troubleshooting.md)
- Review Azure portal for resource status
- Check GitHub Actions logs for CI/CD issues
- Use Azure CLI for manual verification

## Cost Management

### Estimated Costs (Per Environment)
- **Development**: ~$50-100/month
- **Staging**: ~$100-200/month  
- **Production**: ~$200-500/month

### Cost Optimization Tips
- Use auto-terminating clusters
- Implement proper resource tagging
- Monitor usage with Azure Cost Management
- Use spot instances for non-production workloads

## CI/CD Pipeline Features

### Automated Workflows
- Bicep template validation and linting
- Security scanning with Trivy
- Infrastructure testing with what-if analysis
- Multi-environment deployments
- Automated resource cleanup
- Infrastructure destroy capability

### Pipeline Stages
1. **Validate**: Bicep compilation, linting, security scan
2. **What-If**: Generate deployment preview for review
3. **Deploy**: Deploy infrastructure changes
4. **Test**: Verify deployment success
5. **Destroy**: (Optional) Clean up resources to prevent costs
6. **Notify**: Pipeline status notifications

### Key Features
- **OIDC Authentication**: Passwordless authentication with Azure
- **Multi-Environment**: Support for dev, staging, and production
- **Enhanced Global Naming**: Prevents resource conflicts in workshop scenarios
- **Workshop-Safe Deployment**: Multiple participants can deploy simultaneously
- **Cross-Subscription Reliability**: Works across different Azure subscriptions
- **Security Scanning**: Automated vulnerability detection
- **Cost Control**: Easy resource cleanup with destroy functionality

### Learning Resources

#### Workshop Documentation
- [GitHub Setup Guide](docs/github-setup-guide.md) - Complete repository and CI/CD setup
- [Authentication Setup](docs/authentication-setup.md) - Azure OIDC configuration
- [Modular Architecture](docs/modular-architecture.md) - Bicep modular design patterns
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions
- [Validation Checklist](docs/validation-checklist.md) - Pre-delivery validation

#### Tool Comparison
- [Complete Bicep vs Terraform Analysis](BICEP_VS_TERRAFORM_COMPLETE.md) - Comprehensive comparison with working examples

#### External References
- [Azure Databricks Documentation](https://docs.microsoft.com/en-us/azure/databricks/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Contributing

We welcome contributions to improve this workshop:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Areas for Contribution
- Additional data processing examples
- Enhanced security configurations
- Performance optimization guides
- Multi-region deployment patterns

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Azure Databricks team for excellent documentation
- Terraform community for best practices
- NYC Open Data for the sample dataset
- Contributors and workshop participants

---

## Support

For workshop-related questions:
- Create an issue in this repository
- Contact the workshop facilitators

**Happy Learning!**
