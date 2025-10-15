# Azure OIDC Setup Script for GitHub Actions (PowerShell)
# This script sets up OpenID Connect authentication between GitHub Actions and Azure

param(
    [switch]$Help,
    [string]$AppName,
    [string]$RepoName
)

# Color functions for output
function Write-Info { 
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue 
}

function Write-Success { 
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green 
}

function Write-Warning { 
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow 
}

function Write-Error { 
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red 
}

# Help function
function Show-Help {
    Write-Host @"
Azure OIDC Setup Script for GitHub Actions

DESCRIPTION:
    This script configures OpenID Connect authentication between GitHub Actions and Azure,
    eliminating the need for long-lived secrets.

USAGE:
    .\setup-oidc.ps1 [-AppName <name>] [-RepoName <owner/repo>] [-Help]

PARAMETERS:
    -AppName    Optional. Name for the Azure App Registration
    -RepoName   Optional. GitHub repository in format 'owner/repo'
    -Help       Show this help message

EXAMPLES:
    .\setup-oidc.ps1
    .\setup-oidc.ps1 -AppName "MyApp-OIDC" -RepoName "myorg/myrepo"

PREREQUISITES:
    - Azure CLI installed and logged in (az login)
    - GitHub CLI installed and logged in (gh auth login)
    - Appropriate permissions in Azure AD and GitHub repository
"@
}

# Check if help was requested
if ($Help) {
    Show-Help
    exit 0
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check Azure CLI
    try {
        $null = az --version 2>$null
    }
    catch {
        Write-Error "Azure CLI is not installed. Please install it first."
        exit 1
    }
    
    # Check GitHub CLI
    try {
        $null = gh --version 2>$null
    }
    catch {
        Write-Error "GitHub CLI is not installed. Please install it first."
        exit 1
    }
    
    # Check Azure login
    try {
        $null = az account show 2>$null
    }
    catch {
        Write-Error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    }
    
    # Check GitHub login
    try {
        $null = gh auth status 2>$null
    }
    catch {
        Write-Error "Not logged in to GitHub. Please run 'gh auth login' first."
        exit 1
    }
    
    Write-Success "All prerequisites met!"
}

# Get configuration inputs
function Get-Configuration {
    Write-Info "Gathering configuration inputs..."
    
    # Get Azure subscription info
    $script:SubscriptionId = az account show --query id -o tsv
    $script:TenantId = az account show --query tenantId -o tsv
    $subscriptionName = az account show --query name -o tsv
    
    Write-Host "Current Azure subscription: $subscriptionName"
    Write-Host "Subscription ID: $script:SubscriptionId"
    Write-Host "Tenant ID: $script:TenantId"
    
    # Get GitHub repository info
    if (-not $RepoName) {
        try {
            $script:GitHubRepo = gh repo view --json nameWithOwner -q .nameWithOwner
        }
        catch {
            Write-Error "Could not determine GitHub repository. Please specify with -RepoName parameter."
            exit 1
        }
    }
    else {
        $script:GitHubRepo = $RepoName
    }
    
    Write-Host "GitHub Repository: $script:GitHubRepo"
    
    # Set app registration name
    if (-not $AppName) {
        $script:AppRegistrationName = "GitHub-OIDC-$($script:GitHubRepo -replace '/', '-')"
    }
    else {
        $script:AppRegistrationName = $AppName
    }
    
    Write-Host "App Registration Name: $script:AppRegistrationName"
    Write-Host ""
    
    # Confirm with user
    $confirm = Read-Host "Continue with these settings? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Warning "Setup cancelled by user."
        exit 0
    }
}

# Create Azure App Registration
function New-AppRegistration {
    Write-Info "Creating Azure App Registration..."
    
    # Check if app already exists
    $existingApp = az ad app list --display-name $script:AppRegistrationName --query "[0].appId" -o tsv 2>$null
    
    if ($existingApp) {
        Write-Warning "App registration '$script:AppRegistrationName' already exists."
        $script:AppId = $existingApp
    }
    else {
        # Create new app registration
        $script:AppId = az ad app create `
            --display-name $script:AppRegistrationName `
            --sign-in-audience "AzureADMyOrg" `
            --query appId -o tsv
        
        Write-Success "Created app registration with ID: $script:AppId"
    }
}

# Create Service Principal
function New-ServicePrincipal {
    Write-Info "Creating Service Principal..."
    
    # Check if service principal already exists
    $existingSp = az ad sp list --filter "appId eq '$script:AppId'" --query "[0].id" -o tsv 2>$null
    
    if ($existingSp) {
        Write-Warning "Service principal already exists."
    }
    else {
        $null = az ad sp create --id $script:AppId
        Write-Success "Created service principal for app ID: $script:AppId"
    }
}

# Assign Azure roles
function Set-AzureRoles {
    Write-Info "Assigning Azure roles..."
    
    # Assign Contributor role at subscription level
    try {
        $null = az role assignment create `
            --assignee $script:AppId `
            --role "Contributor" `
            --scope "/subscriptions/$script:SubscriptionId" `
            --description "GitHub Actions OIDC for Terraform" 2>$null
        
        Write-Success "Assigned Contributor role to service principal"
    }
    catch {
        Write-Warning "Contributor role may already be assigned"
    }
}

# Create federated identity credentials
function New-FederatedCredentials {
    Write-Info "Creating federated identity credentials..."
    
    # Credential for main branch
    $mainBranchCred = @{
        name = "GitHubMainBranch"
        issuer = "https://token.actions.githubusercontent.com"
        subject = "repo:$($script:GitHubRepo):ref:refs/heads/main"
        audiences = @("api://AzureADTokenExchange")
        description = "GitHub Actions main branch"
    } | ConvertTo-Json -Compress
    
    try {
        $null = az ad app federated-credential create --id $script:AppId --parameters $mainBranchCred 2>$null
    }
    catch {
        Write-Warning "Main branch credential may already exist"
    }
    
    # Credential for develop branch
    $developBranchCred = @{
        name = "GitHubDevelopBranch"
        issuer = "https://token.actions.githubusercontent.com"
        subject = "repo:$($script:GitHubRepo):ref:refs/heads/develop"
        audiences = @("api://AzureADTokenExchange")
        description = "GitHub Actions develop branch"
    } | ConvertTo-Json -Compress
    
    try {
        $null = az ad app federated-credential create --id $script:AppId --parameters $developBranchCred 2>$null
    }
    catch {
        Write-Warning "Develop branch credential may already exist"
    }
    
    # Credential for pull requests
    $pullRequestCred = @{
        name = "GitHubPullRequest"
        issuer = "https://token.actions.githubusercontent.com"
        subject = "repo:$($script:GitHubRepo):pull_request"
        audiences = @("api://AzureADTokenExchange")
        description = "GitHub Actions pull requests"
    } | ConvertTo-Json -Compress
    
    try {
        $null = az ad app federated-credential create --id $script:AppId --parameters $pullRequestCred 2>$null
    }
    catch {
        Write-Warning "Pull request credential may already exist"
    }
    
    Write-Success "Created federated identity credentials"
}

# Set GitHub repository variables
function Set-GitHubVariables {
    Write-Info "Setting GitHub repository variables..."
    
    # Set public variables (non-sensitive)
    gh variable set AZURE_CLIENT_ID --body $script:AppId --repo $script:GitHubRepo
    gh variable set AZURE_TENANT_ID --body $script:TenantId --repo $script:GitHubRepo
    gh variable set AZURE_SUBSCRIPTION_ID --body $script:SubscriptionId --repo $script:GitHubRepo
    
    # Set Terraform state backend variables
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    gh variable set TF_STATE_RESOURCE_GROUP --body "terraform-state-rg" --repo $script:GitHubRepo
    gh variable set TF_STATE_STORAGE_ACCOUNT --body "terraformstate$timestamp" --repo $script:GitHubRepo
    gh variable set TF_STATE_CONTAINER --body "tfstate" --repo $script:GitHubRepo
    
    Write-Success "Set GitHub repository variables"
}

# Clean up old secrets
function Remove-OldSecrets {
    Write-Info "Cleaning up old Service Principal secrets..."
    
    $oldSecrets = @("AZURE_CLIENT_SECRET", "AZURE_CREDENTIALS")
    
    foreach ($secret in $oldSecrets) {
        $secretExists = gh secret list --repo $script:GitHubRepo | Select-String $secret
        if ($secretExists) {
            $remove = Read-Host "Remove old secret '$secret'? (y/N)"
            if ($remove -eq "y" -or $remove -eq "Y") {
                gh secret delete $secret --repo $script:GitHubRepo
                Write-Success "Removed secret: $secret"
            }
        }
    }
}

# Display configuration summary
function Show-Summary {
    Write-Info "OIDC Setup Complete!"
    Write-Host ""
    Write-Host "=== Configuration Summary ===" -ForegroundColor Cyan
    Write-Host "Azure App ID: $script:AppId"
    Write-Host "Azure Tenant ID: $script:TenantId"
    Write-Host "Azure Subscription ID: $script:SubscriptionId"
    Write-Host "GitHub Repository: $script:GitHubRepo"
    Write-Host ""
    Write-Host "=== GitHub Variables Set ===" -ForegroundColor Cyan
    Write-Host "- AZURE_CLIENT_ID"
    Write-Host "- AZURE_TENANT_ID"
    Write-Host "- AZURE_SUBSCRIPTION_ID"
    Write-Host "- TF_STATE_RESOURCE_GROUP"
    Write-Host "- TF_STATE_STORAGE_ACCOUNT"
    Write-Host "- TF_STATE_CONTAINER"
    Write-Host ""
    Write-Host "=== Next Steps ===" -ForegroundColor Cyan
    Write-Host "1. Update your GitHub Actions workflow to use OIDC"
    Write-Host "2. Test the workflow with a pull request"
    Write-Host "3. Remove old Service Principal secrets if no longer needed"
    Write-Host ""
    Write-Host "See module-05-oidc-authentication.md for workflow examples."
}

# Main execution
function Main {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "  Azure OIDC Setup for GitHub Actions" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        Test-Prerequisites
        Get-Configuration
        New-AppRegistration
        New-ServicePrincipal
        Set-AzureRoles
        New-FederatedCredentials
        Set-GitHubVariables
        Remove-OldSecrets
        Show-Summary
        
        Write-Success "Setup completed successfully!"
    }
    catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        exit 1
    }
}

# Run main function
Main