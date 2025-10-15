# Modern Azure Authentication with OpenID Connect

## Overview

This document covers implementing OpenID Connect (OIDC) authentication for secure, zero-maintenance Azure authentication in CI/CD pipelines. OIDC is the **current best practice** for modern cloud authentication.

---

## Why OIDC is the Standard

### Modern Security Architecture
```yaml
# Modern OIDC approach
permissions:
  id-token: write
  contents: read

env:
  ARM_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
  ARM_USE_OIDC: true

steps:
- name: Azure Login with OIDC
  uses: azure/login@v2
  with:
    client-id: ${{ vars.AZURE_CLIENT_ID }}
    tenant-id: ${{ vars.AZURE_TENANT_ID }}
    subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

### Key Benefits
- **Enhanced Security**: No long-lived secrets stored anywhere
- **Zero Maintenance**: Tokens automatically expire and refresh
- **Better Compliance**: Meets modern security standards (Zero Trust)
- **Reduced Risk**: Cannot be compromised through secret leakage
- **Audit Trail**: Complete authentication logging in Azure AD

---

## Implementation Guide

### Prerequisites
- Azure CLI installed and authenticated
- GitHub CLI installed and authenticated
- Azure AD permissions to create App Registrations
- GitHub repository admin access

### Quick Setup

**Automated Setup Script:**
```powershell
# Windows PowerShell
.\scripts\setup-oidc.ps1
```

```bash
# Linux/macOS
./scripts/setup-oidc.sh
```

**Manual Setup Steps:**

1. **Create Azure App Registration**
```bash
az ad app create --display-name "GitHub-OIDC-MyProject"
APP_ID=$(az ad app list --display-name "GitHub-OIDC-MyProject" --query "[0].appId" -o tsv)
```

2. **Create Service Principal**
```bash
az ad sp create --id $APP_ID
az role assignment create --assignee $APP_ID --role "Contributor" --scope "/subscriptions/$SUBSCRIPTION_ID"
```

3. **Configure Federated Identity**
```bash
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "GitHubMainBranch",
  "issuer": "https://token.actions.githubusercontent.com", 
  "subject": "repo:org/repo:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

4. **Set GitHub Variables**
```bash
gh variable set AZURE_CLIENT_ID --body "$APP_ID"
gh variable set AZURE_TENANT_ID --body "$TENANT_ID"
gh variable set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
```

---

## Workflow Configuration

### Complete Example
```yaml
name: 'Modern Terraform CI/CD'

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

permissions:
  id-token: write
  contents: read
  security-events: write

env:
  ARM_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
  ARM_USE_OIDC: true

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: '1.12.1'
    
    - name: Azure Login with OIDC
      uses: azure/login@v2
      with:
        client-id: ${{ vars.AZURE_CLIENT_ID }}
        tenant-id: ${{ vars.AZURE_TENANT_ID }}
        subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
    
    - name: Terraform Init
      run: |
        terraform init \
          -backend-config="resource_group_name=${{ vars.TF_STATE_RESOURCE_GROUP }}" \
          -backend-config="storage_account_name=${{ vars.TF_STATE_STORAGE_ACCOUNT }}" \
          -backend-config="container_name=${{ vars.TF_STATE_CONTAINER }}"
```

---

## Security Considerations

### Federated Identity Configuration

**Subject Claim Patterns:**
| Pattern | Usage |
|---------|-------|
| `repo:org/repo:ref:refs/heads/main` | Main branch only |
| `repo:org/repo:ref:refs/heads/*` | All branches |
| `repo:org/repo:pull_request` | Pull requests |
| `repo:org/repo:environment:prod` | Specific environment |

**Example Federated Credential:**
```json
{
  "name": "GitHubActions",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:your-org/terraform-databricks-workshop:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"],
  "description": "GitHub Actions OIDC for Terraform deployments"
}
```

### Environment-Specific Configuration
```yaml
# Production environment protection
- name: Azure Login (Production)
  uses: azure/login@v2
  with:
    client-id: ${{ vars.AZURE_CLIENT_ID_PROD }}
    tenant-id: ${{ vars.AZURE_TENANT_ID }}
    subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID_PROD }}
  if: github.ref == 'refs/heads/main'
```

---

## Troubleshooting

### Common Issues

**"No matching federated identity record found"**
- **Cause**: Subject claim doesn't match federated credential
- **Solution**: Verify subject pattern matches workflow context
- **Debug**: Check repository name, branch name, and credential configuration

**"Token request failed"**
- **Cause**: Missing permissions in workflow
- **Solution**: Add `id-token: write` permission to workflow
- **Verify**: Ensure permissions block is at job or workflow level

**"AADSTS700024: Client assertion is not within its valid time range"**
- **Cause**: System clock drift on runner
- **Solution**: GitHub-hosted runners shouldn't have this issue
- **Self-hosted**: Ensure NTP synchronization

### Debugging Commands

```bash
# Verify federated credentials
az ad app federated-credential list --id $APP_ID

# Check Azure permissions
az role assignment list --assignee $APP_ID --output table

# Test token in workflow (debugging only)
curl -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
     "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange"
```

---

## Best Practices

### Security
- Use specific federated credential subjects  
- Implement least-privilege Azure role assignments  
- Monitor authentication logs in Azure AD  
- Set up alerts for authentication failures  
- Use environment-specific App Registrations for production  

### Operations
- Use repository variables for non-sensitive configuration  
- Document federated credential patterns  
- Implement proper environment separation  
- Monitor token usage patterns  
- Regular security audits of permissions  

### Development
- Test OIDC setup in development first  
- Use descriptive names for App Registrations  
- Document the setup process for team members  
- Include OIDC configuration in infrastructure code  
- Maintain separation between development and production  

---

## Enterprise Considerations

### Multi-Environment Setup
```bash
# Development environment
az ad app federated-credential create --id $APP_ID_DEV --parameters '{
  "name": "GitHubDev", 
  "subject": "repo:org/repo:ref:refs/heads/develop"
}'

# Production environment  
az ad app federated-credential create --id $APP_ID_PROD --parameters '{
  "name": "GitHubProd",
  "subject": "repo:org/repo:ref:refs/heads/main"
}'
```

### Monitoring and Compliance
- **Azure AD Sign-in Logs**: Monitor all authentication attempts
- **GitHub Audit Log**: Track variable and workflow changes
- **Azure Activity Log**: Monitor resource access patterns
- **Automated Alerts**: Set up notifications for unusual activity

### Backup and Recovery
- **Document Configuration**: Keep App Registration details in secure documentation
- **Backup Scripts**: Maintain scripts to recreate OIDC setup
- **Emergency Access**: Have break-glass procedures for critical issues
- **Recovery Testing**: Regularly test recovery procedures

---

## Resources

### Documentation
- [Azure Workload Identity Federation](https://docs.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation)
- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Terraform Azure Provider OIDC](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)

### Tools
- [OIDC Setup Script (Bash)](../scripts/setup-oidc.sh)
- [OIDC Setup Script (PowerShell)](../scripts/setup-oidc.ps1)
- [Workshop Implementation Guide](./authentication-setup.md)

### Training
- [Azure AD Workload Identity Federation](https://learn.microsoft.com/en-us/training/modules/implement-workload-identity/)
- [GitHub Actions Security](https://learn.microsoft.com/en-us/training/modules/secure-github-actions/)
- [Zero Trust Security Model](https://learn.microsoft.com/en-us/training/modules/introduction-zero-trust/)