# Azure Authentication Setup Guide

## Modern Approach: OpenID Connect (OIDC)

For all new projects, use OIDC authentication for maximum security and zero maintenance.

### Quick Setup

**Prerequisites:**
- Azure CLI installed and logged in (`az login`)
- GitHub CLI installed and logged in (`gh auth login`)
- Azure AD permissions to create App Registrations

**Run the automated setup:**

```powershell
# Windows PowerShell
.\scripts\setup-oidc.ps1
```

```bash
# Linux/macOS
./scripts/setup-oidc.sh
```

**What the script does:**
1. Creates Azure App Registration 
2. Configures federated identity credentials
3. Assigns Azure Contributor role
4. Sets GitHub repository variables
5. Provides configuration summary

**GitHub Variables Created:**
- `AZURE_CLIENT_ID` - App Registration ID
- `AZURE_TENANT_ID` - Azure AD Tenant ID  
- `AZURE_SUBSCRIPTION_ID` - Target Azure subscription

---

## Workflow Configuration

### Modern OIDC Workflow

```yaml
name: 'Bicep CI/CD'

permissions:
  id-token: write
  contents: read

env:
  AZURE_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
  AZURE_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
  AZURE_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}

jobs:
  bicep:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Azure Login with OIDC
      uses: azure/login@v2
      with:
        client-id: ${{ vars.AZURE_CLIENT_ID }}
        tenant-id: ${{ vars.AZURE_TENANT_ID }}
        subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

---

## Benefits

| Feature | OIDC Advantage |
|---------|----------------|
| **Token Lifetime** | 1 hour (automatic refresh) |
| **Maintenance** | Zero maintenance required |
| **Security Risk** | Very low - no secrets to compromise |
| **Storage Type** | GitHub Variables (public configuration) |
| **Setup Complexity** | One-time automated setup |
| **Compliance** | Built-in modern security standards |

---

## Troubleshooting

### Common Issues

**"No matching federated identity record found"**
- Verify repository name matches federated credential
- Check branch name (main vs master)
- Ensure workflow has `id-token: write` permission

**"Token request failed"**
- Add `permissions: id-token: write` to workflow
- Verify Azure App Registration exists
- Check federated credential configuration

### Debug Commands

```bash
# Verify federated credentials
az ad app federated-credential list --id $APP_ID

# Check service principal permissions
az role assignment list --assignee $APP_ID --output table

# Verify GitHub variables
gh variable list
```

---

## Best Practices

- Use repository variables for non-sensitive data  
- Set specific federated credential subjects  
- Use least-privilege Azure role assignments  
- Monitor authentication logs in Azure AD  
- Set up alerts for authentication failures  
- Use environment-specific credentials for production  
- Document setup process for team members  
- Test in development environment first  

---

## Next Steps

After authentication setup:

1. **Test the authentication** with a simple workflow
2. **Deploy Bicep infrastructure** following Module 2-3
3. **Set up data pipelines** following Module 4
4. **Implement full CI/CD** following Module 5
5. **Monitor and maintain** the deployment

For detailed implementation, see the full workshop modules in the `presentation/` directory.