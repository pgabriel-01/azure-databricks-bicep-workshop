# Databricks Module - Azure Databricks Workspace
# This module creates the Databricks workspace with VNet injection

# Data source for resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Azure Databricks Workspace
resource "azurerm_databricks_workspace" "main" {
  name                        = "${var.resource_prefix}-databricks"
  resource_group_name         = data.azurerm_resource_group.main.name
  location                    = var.location
  sku                         = var.databricks_sku
  managed_resource_group_name = "${var.resource_prefix}-databricks-managed-rg"

  custom_parameters {
    no_public_ip        = var.no_public_ip
    virtual_network_id  = var.vnet_id != "" ? var.vnet_id : null
    public_subnet_name  = var.vnet_id != "" ? var.public_subnet_name : null
    private_subnet_name = var.vnet_id != "" ? var.private_subnet_name : null

    public_subnet_network_security_group_association_id  = var.vnet_id != "" ? var.public_subnet_nsg_association_id : null
    private_subnet_network_security_group_association_id = var.vnet_id != "" ? var.private_subnet_nsg_association_id : null
  }

  tags = var.tags
}