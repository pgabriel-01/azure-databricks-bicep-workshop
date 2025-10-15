# Networking Module Outputs

output "vnet_id" {
  description = "Virtual network resource ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.main.name
}

output "public_subnet_id" {
  description = "Public subnet resource ID"
  value       = azurerm_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet resource ID"
  value       = azurerm_subnet.private.id
}

output "public_subnet_name" {
  description = "Public subnet name"
  value       = azurerm_subnet.public.name
}

output "private_subnet_name" {
  description = "Private subnet name"
  value       = azurerm_subnet.private.name
}

output "public_nsg_id" {
  description = "Public NSG resource ID"
  value       = azurerm_network_security_group.public.id
}

output "private_nsg_id" {
  description = "Private NSG resource ID"
  value       = azurerm_network_security_group.private.id
}