# Security Module - Key Vault, Log Analytics for Databricks
# This module creates security and monitoring infrastructure

# Data source for resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.resource_prefix}-law"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# Key Vault for storing secrets
resource "azurerm_key_vault" "main" {
  name                        = substr("${var.resource_prefix}-kv-${var.suffix}", 0, 24)
  location                    = var.location
  resource_group_name         = data.azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = var.environment == "prod" ? true : false

  sku_name = var.key_vault_sku

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}