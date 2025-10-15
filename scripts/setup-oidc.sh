#!/bin/bash

# Azure OIDC Setup Script for GitHub Actions
# This script sets up OpenID Connect authentication between GitHub Actions and Azure

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if user is logged in to GitHub
    if ! gh auth status &> /dev/null; then
        print_error "Not logged in to GitHub. Please run 'gh auth login' first."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Get user inputs
get_inputs() {
    print_status "Gathering configuration inputs..."
    
    # Get subscription info
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    TENANT_ID=$(az account show --query tenantId -o tsv)
    
    echo "Current Azure subscription: $(az account show --query name -o tsv)"
    echo "Subscription ID: $SUBSCRIPTION_ID"
    echo "Tenant ID: $TENANT_ID"
    
    # Get GitHub repository info
    GITHUB_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    echo "GitHub Repository: $GITHUB_REPO"
    
    # App registration name
    APP_NAME="GitHub-OIDC-${GITHUB_REPO//\//-}"
    echo "App Registration Name: $APP_NAME"
    
    # Confirm with user
    echo ""
    read -p "Continue with these settings? (y/N): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        print_warning "Setup cancelled by user."
        exit 0
    fi
}

# Create Azure App Registration
create_app_registration() {
    print_status "Creating Azure App Registration..."
    
    # Check if app already exists
    existing_app=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$existing_app" ]]; then
        print_warning "App registration '$APP_NAME' already exists."
        APP_ID="$existing_app"
    else
        # Create new app registration
        APP_ID=$(az ad app create \
            --display-name "$APP_NAME" \
            --sign-in-audience "AzureADMyOrg" \
            --query appId -o tsv)
        print_success "Created app registration with ID: $APP_ID"
    fi
}

# Create Service Principal
create_service_principal() {
    print_status "Creating Service Principal..."
    
    # Check if service principal already exists
    existing_sp=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$existing_sp" ]]; then
        print_warning "Service principal already exists."
    else
        az ad sp create --id "$APP_ID" > /dev/null
        print_success "Created service principal for app ID: $APP_ID"
    fi
}

# Assign Azure roles
assign_roles() {
    print_status "Assigning Azure roles..."
    
    # Assign Contributor role at subscription level
    az role assignment create \
        --assignee "$APP_ID" \
        --role "Contributor" \
        --scope "/subscriptions/$SUBSCRIPTION_ID" \
        --description "GitHub Actions OIDC for Terraform" \
        > /dev/null 2>&1 || print_warning "Contributor role may already be assigned"
    
    print_success "Assigned Contributor role to service principal"
}

# Create federated identity credentials
create_federated_credentials() {
    print_status "Creating federated identity credentials..."
    
    # Create credential for main branch
    az ad app federated-credential create \
        --id "$APP_ID" \
        --parameters '{
            "name": "GitHubMainBranch",
            "issuer": "https://token.actions.githubusercontent.com",
            "subject": "repo:'$GITHUB_REPO':ref:refs/heads/main",
            "audiences": ["api://AzureADTokenExchange"],
            "description": "GitHub Actions main branch"
        }' > /dev/null 2>&1 || print_warning "Main branch credential may already exist"
    
    # Create credential for develop branch
    az ad app federated-credential create \
        --id "$APP_ID" \
        --parameters '{
            "name": "GitHubDevelopBranch",
            "issuer": "https://token.actions.githubusercontent.com",
            "subject": "repo:'$GITHUB_REPO':ref:refs/heads/develop",
            "audiences": ["api://AzureADTokenExchange"],
            "description": "GitHub Actions develop branch"
        }' > /dev/null 2>&1 || print_warning "Develop branch credential may already exist"
    
    # Create credential for pull requests
    az ad app federated-credential create \
        --id "$APP_ID" \
        --parameters '{
            "name": "GitHubPullRequest",
            "issuer": "https://token.actions.githubusercontent.com",
            "subject": "repo:'$GITHUB_REPO':pull_request",
            "audiences": ["api://AzureADTokenExchange"],
            "description": "GitHub Actions pull requests"
        }' > /dev/null 2>&1 || print_warning "Pull request credential may already exist"
    
    print_success "Created federated identity credentials"
}

# Set GitHub repository variables
set_github_variables() {
    print_status "Setting GitHub repository variables..."
    
    # Set public variables (non-sensitive)
    gh variable set AZURE_CLIENT_ID --body "$APP_ID" --repo "$GITHUB_REPO"
    gh variable set AZURE_TENANT_ID --body "$TENANT_ID" --repo "$GITHUB_REPO"
    gh variable set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID" --repo "$GITHUB_REPO"
    
    # Set Terraform state backend variables
    gh variable set TF_STATE_RESOURCE_GROUP --body "terraform-state-rg" --repo "$GITHUB_REPO"
    gh variable set TF_STATE_STORAGE_ACCOUNT --body "terraformstate$(date +%s)" --repo "$GITHUB_REPO"
    gh variable set TF_STATE_CONTAINER --body "tfstate" --repo "$GITHUB_REPO"
    
    print_success "Set GitHub repository variables"
}

# Clean up old secrets (optional)
cleanup_old_secrets() {
    print_status "Cleaning up old Service Principal secrets..."
    
    # List of old secrets to remove
    old_secrets=("AZURE_CLIENT_SECRET" "AZURE_CREDENTIALS")
    
    for secret in "${old_secrets[@]}"; do
        if gh secret list --repo "$GITHUB_REPO" | grep -q "$secret"; then
            read -p "Remove old secret '$secret'? (y/N): " remove_secret
            if [[ $remove_secret == "y" || $remove_secret == "Y" ]]; then
                gh secret delete "$secret" --repo "$GITHUB_REPO"
                print_success "Removed secret: $secret"
            fi
        fi
    done
}

# Display summary
display_summary() {
    print_status "OIDC Setup Complete!"
    echo ""
    echo "=== Configuration Summary ==="
    echo "Azure App ID: $APP_ID"
    echo "Azure Tenant ID: $TENANT_ID"
    echo "Azure Subscription ID: $SUBSCRIPTION_ID"
    echo "GitHub Repository: $GITHUB_REPO"
    echo ""
    echo "=== GitHub Variables Set ==="
    echo "- AZURE_CLIENT_ID"
    echo "- AZURE_TENANT_ID"
    echo "- AZURE_SUBSCRIPTION_ID"
    echo "- TF_STATE_RESOURCE_GROUP"
    echo "- TF_STATE_STORAGE_ACCOUNT"
    echo "- TF_STATE_CONTAINER"
    echo ""
    echo "=== Next Steps ==="
    echo "1. Update your GitHub Actions workflow to use OIDC"
    echo "2. Test the workflow with a pull request"
    echo "3. Remove old Service Principal secrets if no longer needed"
    echo ""
    echo "See module-05-oidc-authentication.md for workflow examples."
}

# Main execution
main() {
    echo "========================================="
    echo "  Azure OIDC Setup for GitHub Actions"
    echo "========================================="
    echo ""
    
    check_prerequisites
    get_inputs
    create_app_registration
    create_service_principal
    assign_roles
    create_federated_credentials
    set_github_variables
    cleanup_old_secrets
    display_summary
    
    print_success "Setup completed successfully!"
}

# Run main function
main "$@"