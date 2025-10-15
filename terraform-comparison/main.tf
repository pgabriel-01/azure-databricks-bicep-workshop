# Terraform Azure Databricks Workshop - Main Configuration
# This demonstrates the same infrastructure as the Bicep version
# Compare with ../bicep/main.bicep to understand the differences

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Remote state configuration (uncomment for production use)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "terraformstateXXXXX"
  #   container_name       = "tfstate"
  #   key                  = "databricks-workshop.terraform.tfstate"
  # }
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Data source for resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Local values for consistent naming and tagging
locals {
  resource_prefix = "${var.environment}-${var.project_name}"
  common_tags = {
    Environment    = var.environment
    Project        = var.project_name
    Owner          = var.owner
    CostCenter     = var.cost_center
    DeployedBy     = "Terraform"
    DeploymentTime = timestamp()
  }
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  resource_prefix        = local.resource_prefix
  location              = var.location
  resource_group_name   = var.resource_group_name
  vnet_address_prefix   = var.vnet_address_prefix
  public_subnet_prefix  = var.public_subnet_prefix
  private_subnet_prefix = var.private_subnet_prefix
  tags                  = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  resource_prefix      = local.resource_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  environment         = var.environment
  log_retention_days  = var.log_retention_days
  key_vault_sku       = var.key_vault_sku
  tenant_id           = data.azurerm_client_config.current.tenant_id
  suffix              = random_string.suffix.result
  tags                = local.common_tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  resource_prefix           = local.resource_prefix
  location                 = var.location
  resource_group_name      = var.resource_group_name
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type
  key_vault_id            = module.security.key_vault_id
  suffix                  = random_string.suffix.result
  tags                    = local.common_tags

  depends_on = [module.security]
}

# Databricks Module
module "databricks" {
  source = "./modules/databricks"

  resource_prefix        = local.resource_prefix
  location              = var.location
  resource_group_name   = var.resource_group_name
  databricks_sku        = var.databricks_sku
  no_public_ip          = var.no_public_ip
  vnet_id               = module.networking.vnet_id
  public_subnet_name    = module.networking.public_subnet_name
  private_subnet_name   = module.networking.private_subnet_name
  tags                  = local.common_tags

  depends_on = [module.networking, module.security, module.storage]
}