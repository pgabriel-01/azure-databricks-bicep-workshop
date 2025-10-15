# GitHub Setup and Testing Guide

## Prerequisites for Testing

### 1. Azure Subscription Setup
You'll need an Azure subscription with the following permissions:
- **Contributor** role at the subscription or resource group level
- **User Access Administrator** role for RBAC assignments
- Permission to create **App Registrations** in Azure AD

### 2. GitHub Account
- New GitHub account (as mentioned)
- Ability to create repositories
- GitHub Actions enabled

## Step-by-Step Setup Guide

### Phase 1: Azure Service Principal Setup

#### 1.1 Create Service Principal for OIDC
```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create service principal for GitHub Actions
az ad sp create-for-rbac --name "github-actions-databricks-workshop" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth

# Enable OIDC for the service principal
az ad app update --id YOUR_APP_ID --identifier-uris api://YOUR_APP_ID
```

#### 1.2 Configure Federated Identity Credential
```bash
# Create federated credential for GitHub Actions
az ad app federated-credential create \
  --id YOUR_APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_USERNAME/azure-databricks-bicep-workshop:ref:refs/heads/main",
    "description": "GitHub Actions Main Branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for pull requests
az ad app federated-credential create \
  --id YOUR_APP_ID \
  --parameters '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_USERNAME/azure-databricks-bicep-workshop:pull_request",
    "description": "GitHub Actions Pull Requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Phase 2: GitHub Repository Setup

#### 2.1 Create GitHub Repository
1. Go to GitHub and create a new repository named `azure-databricks-bicep-workshop`
2. Choose **Public** or **Private** (your preference)
3. Initialize with README: **No** (we have our own)

#### 2.2 Configure Repository Variables
Go to Repository Settings → Secrets and Variables → Actions → Variables

**Repository Variables:**
```
AZURE_CLIENT_ID: YOUR_SERVICE_PRINCIPAL_CLIENT_ID
AZURE_TENANT_ID: YOUR_AZURE_TENANT_ID  
AZURE_SUBSCRIPTION_ID: YOUR_AZURE_SUBSCRIPTION_ID
```

#### 2.3 Create Resource Groups
```bash
# Create resource groups for different environments
az group create --name "rg-databricks-dev" --location "East US"
az group create --name "rg-databricks-staging" --location "East US"
az group create --name "rg-databricks-prod" --location "East US"
```

### Phase 3: Repository Setup

#### 3.1 Initialize Git Repository
```bash
cd d:\Desktop\Skillsoft_Repo

# Initialize git repository
git init

# Add GitHub repository as remote
git remote add origin https://github.com/YOUR_USERNAME/azure-databricks-bicep-workshop.git

# Add all files
git add .

# Commit initial version
git commit -m "Initial commit: Bicep Azure Databricks Workshop with modular architecture

- Modular Bicep templates (networking, security, storage, databricks)
- GitHub Actions CI/CD pipeline with OIDC authentication
- Multi-environment parameter files (dev, staging, prod)
- Comprehensive presentation materials for workshop delivery
- Security scanning and best practices implementation"

# Push to GitHub
git push -u origin main
```

### Phase 4: Testing Sequence

#### 4.1 Validate GitHub Actions Workflow
1. **Check workflow file**: `.github/workflows/bicep-clean.yml`
2. **Trigger workflow**: Push to main branch should trigger the pipeline
3. **Monitor execution**: Check Actions tab in GitHub repository

#### 4.2 Test Bicep Template Validation
The GitHub Actions workflow will:
- Lint all Bicep templates
- Validate templates against Azure
- Run what-if analysis
- Perform security scanning
- Run deployment tests

#### 4.3 Test Manual Deployment
```bash
# Test dev environment deployment
az deployment group create \
  --resource-group "rg-databricks-dev" \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/dev.bicepparam \
  --name "manual-test-$(date +%Y%m%d-%H%M%S)"

# Check deployment status
az deployment group show \
  --resource-group "rg-databricks-dev" \
  --name "manual-test-TIMESTAMP" \
  --query "properties.provisioningState"
```

### Phase 5: Verification Checklist

#### Infrastructure Validation
- [ ] **Virtual Network**: VNet created with proper subnets
- [ ] **Network Security Groups**: NSGs attached to subnets
- [ ] **Storage Account**: Data Lake Gen2 enabled storage
- [ ] **Key Vault**: Secrets storage with proper access policies
- [ ] **Log Analytics**: Monitoring workspace created
- [ ] **Databricks Workspace**: Workspace deployed with VNet injection

#### Security Validation
- [ ] **OIDC Authentication**: No secrets stored in GitHub
- [ ] **Resource Naming**: Consistent naming conventions
- [ ] **Tagging**: All resources properly tagged
- [ ] **Network Security**: NSG rules applied correctly

#### CI/CD Pipeline Validation
- [ ] **Workflow Triggers**: Pipeline runs on push/PR
- [ ] **Template Validation**: All templates validate successfully
- [ ] **Security Scanning**: Trivy, PSRule, Checkov complete
- [ ] **What-If Analysis**: Shows expected changes
- [ ] **Multi-Environment**: Dev/staging/prod deployments work

### Phase 6: Workshop Testing

#### 6.1 Presentation Materials
- [ ] **Module 1**: IaC fundamentals work correctly
- [ ] **Module 2**: Bicep best practices examples functional
- [ ] **Module 3**: Databricks deployment examples work
- [ ] **Module 5**: CI/CD pipeline examples match actual workflow

#### 6.2 Lab Exercises
- [ ] **Lab 1**: Template modification exercises
- [ ] **Lab 2**: Parameter customization
- [ ] **Lab 3**: Module creation
- [ ] **Lab 4**: Pipeline customization

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue: GitHub Actions Authentication Fails
**Solution**: 
- Verify repository variables are set correctly
- Check federated identity credential configuration
- Ensure service principal has correct permissions

#### Issue: Bicep Template Validation Fails
**Solution**:
- Run `az bicep build` locally first
- Check resource naming conventions
- Verify parameter file references

#### Issue: Resource Deployment Fails
**Solution**:
- Check resource group exists
- Verify Azure permissions
- Review deployment error messages

#### Issue: What-If Analysis Shows Unexpected Changes
**Solution**:
- Compare with previous deployments
- Check for API version changes
- Verify parameter file values

## Next Steps After Successful Testing

1. **Workshop Delivery Preparation**
   - Test all demo scenarios
   - Prepare lab environment
   - Create participant access

2. **Production Hardening**
   - Enable additional security features
   - Configure monitoring and alerting
   - Set up backup and disaster recovery

3. **Documentation Updates**
   - Update with actual deployment screenshots
   - Add troubleshooting scenarios
   - Include participant guides

## Support Resources

- **Azure Bicep Documentation**: https://docs.microsoft.com/azure/azure-resource-manager/bicep/
- **GitHub Actions Documentation**: https://docs.github.com/actions
- **Azure Databricks Documentation**: https://docs.microsoft.com/azure/databricks/

Ready to start testing!