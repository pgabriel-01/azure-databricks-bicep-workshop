# Bicep Azure Databricks Workshop

A comprehensive workshop demonstrating Infrastructure as Code best practices with Bicep, Azure Databricks, and CI/CD pipelines using GitHub Actions.

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
│       └── bicep.yml               # CI/CD pipeline
├── bicep/
│   ├── main.bicep                  # Main Bicep template
│   ├── parameters/                 # Parameter files
│   │   ├── dev.bicepparam         # Development parameters
│   │   ├── staging.bicepparam     # Staging parameters
│   │   └── prod.bicepparam        # Production parameters
│   └── modules/
│       └── databricks/             # Reusable Databricks module
│   └── environments/
│       ├── dev/                   # Development environment
│       ├── staging/               # Staging environment
│       └── prod/                  # Production environment
├── databricks/
│   ├── notebooks/                 # Databricks notebooks
│   └── jobs/                      # Job configurations
├── bicep-comparison/
│   ├── main.bicep                 # Equivalent Bicep template
│   └── README.md                  # Terraform vs Bicep comparison
├── docs/                          # Workshop documentation
├── datasets/                      # Sample datasets
└── scripts/                       # Utility scripts
```

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/bicep-databricks-workshop.git
cd bicep-databricks-workshop
```

### 2. Set Up Azure OIDC Authentication

**For Windows (PowerShell):**
```powershell
# Login to Azure and GitHub
az login
gh auth login

# Run OIDC setup script
.\scripts\setup-oidc.ps1
```

**For Linux/macOS (Bash):**
```bash
# Login to Azure and GitHub
az login
gh auth login

# Run OIDC setup script
./scripts/setup-oidc.sh
```

The script will automatically:
- Create Azure App Registration with OIDC federation
- Set up GitHub repository variables
- Configure federated identity credentials
- Provide you with the configuration details

### 3. Verify OIDC Setup

After running the setup script, verify your GitHub repository has these variables:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID` 
- `AZURE_SUBSCRIPTION_ID`
- `BICEP_STATE_RESOURCE_GROUP`
- `BICEP_STATE_STORAGE_ACCOUNT`
- `BICEP_STATE_CONTAINER`

The Bicep deployment will use these variables for authentication and state management.
    storage_account_name = "terraformstatesa"
    container_name       = "tfstate"
    key                  = "databricks-workshop.tfstate"
  }
}
```

### 4. Deploy Infrastructure

```bash
cd bicep

# Deploy infrastructure to development environment
az deployment group create \
  --resource-group "bicep-databricks-dev-rg" \
  --template-file main.bicep \
  --parameters dev.bicepparam

# Get deployment outputs
az deployment group show \
  --resource-group "bicep-databricks-dev-rg" \
  --name "main" \
  --query properties.outputs
```

### 5. Access Your Databricks Workspace

After deployment, get the workspace URL from the outputs:

```bash
az deployment group show \
  --resource-group "bicep-databricks-dev-rg" \
  --name "main" \
  --query properties.outputs.databricksWorkspaceUrl.value
```

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
- Automated deployments
- **Hands-on**: Set up complete CI/CD pipeline with OIDC authentication

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

## Terraform Best Practices Demonstrated

### Project Organization
- Consistent naming conventions
- Environment-specific configurations
- Reusable modules
- Proper tagging strategy

### State Management
- Remote state storage
- State locking
- Workspace separation
- State file encryption

### Code Quality
- Input validation
- Output documentation
- Resource dependencies
- Error handling

### Security
- Secret management
- Least privilege access
- Network isolation
- Encryption at rest and in transit

## Troubleshooting

### Common Issues

**Terraform Authentication Errors**
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

**State File Issues**
```bash
# Force unlock if state is stuck
terraform force-unlock LOCK_ID

# Import existing resources
terraform import azurerm_resource_group.main /subscriptions/SUB_ID/resourceGroups/RG_NAME
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
- Terraform validation and formatting
- Security scanning with Trivy
- Infrastructure testing
- Multi-environment deployments
- Databricks artifact deployment
- Automated rollback capabilities

### Pipeline Stages
1. **Validate**: Format check, linting, security scan
2. **Plan**: Generate execution plans for review
3. **Apply**: Deploy infrastructure changes
4. **Test**: Run infrastructure and data quality tests
5. **Deploy**: Update Databricks notebooks and jobs
6. **Notify**: Team notifications via Teams/Slack

## Learning Resources

### Documentation
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Databricks Documentation](https://docs.microsoft.com/en-us/azure/databricks/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Additional Learning
- [Terraform Best Practices Guide](docs/terraform-best-practices.md)
- [Azure Databricks Patterns](docs/databricks-patterns.md)
- [CI/CD Pipeline Guide](docs/cicd-guide.md)

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
- Join our Slack workspace: [workspace-link]

**Happy Learning!**