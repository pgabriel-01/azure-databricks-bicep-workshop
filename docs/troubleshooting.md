# Troubleshooting Guide

This guide covers common issues and solutions when working with the Azure Databricks Bicep Workshop.

## Azure Authentication Issues

### Service Principal Authentication Errors

**Symptom**: Authentication failures in GitHub Actions
```
ERROR: AADSTS700016: Application with identifier 'xxx' was not found
```

**Solutions**:
1. Verify service principal exists:
   ```bash
   az ad app list --display-name "GitHub-OIDC-*"
   ```

2. Check OIDC federated credentials:
   ```bash
   az ad app federated-credential list --id YOUR_APP_ID
   ```

3. Verify repository variables in GitHub:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

### Insufficient Permissions

**Symptom**: Authorization errors during deployment
```
ERROR: The client does not have authorization to perform action
```

**Solutions**:
1. Verify service principal has Contributor role:
   ```bash
   az role assignment list --assignee YOUR_CLIENT_ID --scope /subscriptions/YOUR_SUBSCRIPTION_ID
   ```

2. Add required role if missing:
   ```bash
   az role assignment create \
     --assignee YOUR_CLIENT_ID \
     --role "Contributor" \
     --scope /subscriptions/YOUR_SUBSCRIPTION_ID
   ```

## Bicep Template Issues

### Compilation Errors

**Symptom**: Bicep templates fail to compile
```
ERROR: The template parameter 'xxx' is not defined
```

**Solutions**:
1. Validate template syntax:
   ```bash
   az bicep build --file bicep/main.bicep
   ```

2. Check parameter files:
   ```bash
   az bicep build-params --file bicep/parameters/dev.bicepparam
   ```

3. Verify module references are correct in main template

### Resource Naming Conflicts

**Symptom**: Deployment fails due to existing resources
```
ERROR: The storage account name 'xxx' is already taken
```

**Solutions**:
1. Use unique naming with suffix:
   ```bicep
   var storageAccountName = '${prefix}sa${uniqueString(resourceGroup().id)}'
   ```

2. Check for existing resources:
   ```bash
   az resource list --resource-group YOUR_RG_NAME
   ```

3. Clean up conflicting resources if safe to do so

## Azure Databricks Issues

### VNet Injection Failures

**Symptom**: Databricks workspace creation fails
```
ERROR: The provided subnet has invalid configuration for Databricks VNet injection
```

**Solutions**:
1. Verify subnet configuration:
   - Public subnet: `/26` or larger
   - Private subnet: `/26` or larger
   - Proper NSG rules applied

2. Check NSG rules include required Databricks rules:
   ```bash
   az network nsg rule list --resource-group YOUR_RG --nsg-name YOUR_NSG
   ```

3. Ensure subnets aren't already delegated to other services

### Workspace Access Issues

**Symptom**: Cannot access Databricks workspace
```
ERROR: Workspace is not accessible
```

**Solutions**:
1. Check workspace state:
   ```bash
   az databricks workspace show --resource-group YOUR_RG --name YOUR_WORKSPACE
   ```

2. Verify network connectivity if using VNet injection

3. Check Azure AD permissions for workspace access

## GitHub Actions Issues

### Workflow Failures

**Symptom**: GitHub Actions workflow fails unexpectedly

**Common Causes & Solutions**:

1. **What-If Analysis Fails**:
   ```bash
   # Test locally
   az deployment group what-if \
     --resource-group "rg-databricks-dev" \
     --template-file bicep/main.bicep \
     --parameters bicep/parameters/dev.bicepparam
   ```

2. **Security Scanning Issues**:
   - Check Trivy, PSRule, and Checkov outputs
   - Review security scanning logs in Actions tab

3. **Deployment Timeouts**:
   - Increase timeout in workflow file
   - Check Azure portal for stuck deployments

### OIDC Token Issues

**Symptom**: Token exchange failures
```
ERROR: OIDC token could not be verified
```

**Solutions**:
1. Verify federated credential subject matches:
   ```
   repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main
   ```

2. Check token permissions in workflow:
   ```yaml
   permissions:
     id-token: write
     contents: read
   ```

## Storage Account Issues

### Data Lake Gen2 Configuration

**Symptom**: Storage account doesn't support Data Lake features
```
ERROR: Hierarchical namespace is not enabled
```

**Solutions**:
1. Verify Data Lake Gen2 is enabled:
   ```bicep
   properties: {
     isHnsEnabled: true
   }
   ```

2. Check account kind is StorageV2:
   ```bicep
   kind: 'StorageV2'
   ```

### Container Access Issues

**Symptom**: Cannot access blob containers
```
ERROR: This request is not authorized
```

**Solutions**:
1. Check container public access settings
2. Verify storage account firewall rules
3. Ensure proper RBAC assignments

## Key Vault Issues

### Access Policy Configuration

**Symptom**: Cannot access secrets in Key Vault
```
ERROR: Access denied
```

**Solutions**:
1. Verify Key Vault access policies:
   ```bash
   az keyvault show --name YOUR_KEYVAULT --resource-group YOUR_RG
   ```

2. Add required access policies:
   ```bash
   az keyvault set-policy \
     --name YOUR_KEYVAULT \
     --upn YOUR_USER@domain.com \
     --secret-permissions get list
   ```

### Purge Protection Issues

**Symptom**: Key Vault deployment fails due to soft-deleted vault
```
ERROR: Vault name is already in use
```

**Solutions**:
1. List soft-deleted vaults:
   ```bash
   az keyvault list-deleted
   ```

2. Purge soft-deleted vault (if safe):
   ```bash
   az keyvault purge --name YOUR_KEYVAULT --location YOUR_LOCATION
   ```

## Network Security Group Issues

### Databricks NSG Rules

**Symptom**: Databricks clusters fail to start
```
ERROR: Network security group blocks required traffic
```

**Required NSG Rules**:
```bash
# Worker to Azure SQL (port 3342)
az network nsg rule create --priority 100 --name "databricks-worker-to-sql"

# Worker to Storage (port 443)  
az network nsg rule create --priority 101 --name "databricks-worker-to-storage"

# Worker to Worker communication
az network nsg rule create --priority 102 --name "databricks-worker-to-worker"

# Control plane to worker (port 5557)
az network nsg rule create --priority 103 --name "databricks-control-to-worker"
```

## Common Commands for Diagnosis

### Azure CLI Diagnostics
```bash
# Check current context
az account show

# List all resources in resource group
az resource list --resource-group YOUR_RG --output table

# Check deployment status
az deployment group list --resource-group YOUR_RG --output table

# Get deployment details
az deployment group show --resource-group YOUR_RG --name YOUR_DEPLOYMENT
```

### Bicep Diagnostics
```bash
# Validate all templates
az bicep build --file bicep/main.bicep
for file in bicep/modules/*.bicep; do
  az bicep build --file "$file"
done

# Check parameter files
az bicep build-params --file bicep/parameters/dev.bicepparam
```

### GitHub Actions Diagnostics
```bash
# Check workflow runs
gh run list --limit 10

# View specific run details
gh run view RUN_ID

# Download logs
gh run download RUN_ID
```

## Getting Additional Help

### Resources
- [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Azure Databricks Documentation](https://docs.microsoft.com/azure/databricks/)

### Support Channels
1. **GitHub Issues**: Create an issue in this repository
2. **Azure Support**: Use Azure portal support for Azure-specific issues
3. **Community Forums**: Stack Overflow with relevant tags

### Logging and Monitoring
1. **GitHub Actions Logs**: Available in repository Actions tab
2. **Azure Activity Log**: Monitor deployment activities
3. **Databricks Logs**: Check workspace logs for cluster issues

---

**Note**: Always ensure you have proper backup procedures before making changes to production environments.