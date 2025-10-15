# Databricks Module Outputs

output "workspace_id" {
  description = "Databricks workspace resource ID"
  value       = azurerm_databricks_workspace.main.id
}

output "workspace_name" {
  description = "Databricks workspace name"
  value       = azurerm_databricks_workspace.main.name
}

output "workspace_url" {
  description = "Databricks workspace URL"
  value       = "https://${azurerm_databricks_workspace.main.workspace_url}"
}

output "managed_resource_group_name" {
  description = "Managed resource group name"
  value       = azurerm_databricks_workspace.main.managed_resource_group_name
}