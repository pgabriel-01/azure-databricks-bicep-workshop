# Storage Module - Data Lake Storage for Databricks
# This module creates storage infrastructure for data processing

# Data source for resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Storage Account with Data Lake Gen2 capabilities
resource "azurerm_storage_account" "main" {
  name                     = substr(replace("${var.resource_prefix}datalake${var.suffix}", "-", ""), 0, 24)
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"
  is_hns_enabled           = true # Enable hierarchical namespace for Data Lake
  access_tier              = "Hot"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

# Raw data container
resource "azurerm_storage_container" "raw_data" {
  name                 = "raw-data"
  storage_account_name = azurerm_storage_account.main.name
}

# Processed data container
resource "azurerm_storage_container" "processed_data" {
  name                 = "processed-data"
  storage_account_name = azurerm_storage_account.main.name
}

# Store storage connection string in Key Vault
resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.main.primary_connection_string
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_storage_account.main]
}