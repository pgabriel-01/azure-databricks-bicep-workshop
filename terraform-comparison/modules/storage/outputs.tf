# Storage Module Outputs

output "storage_account_id" {
  description = "Storage account resource ID"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_endpoint" {
  description = "Storage account primary endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "raw_data_container_name" {
  description = "Raw data container name"
  value       = azurerm_storage_container.raw_data.name
}

output "processed_data_container_name" {
  description = "Processed data container name"
  value       = azurerm_storage_container.processed_data.name
}

output "storage_connection_string_secret_name" {
  description = "Storage connection string secret name"
  value       = azurerm_key_vault_secret.storage_connection_string.name
}