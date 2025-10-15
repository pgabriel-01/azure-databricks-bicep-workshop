# Databricks Module Variables

variable "resource_prefix" {
  description = "Resource prefix for naming"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "databricks_sku" {
  description = "SKU for Azure Databricks workspace"
  type        = string
  default     = "standard"
}

variable "no_public_ip" {
  description = "Enable no public IP for Databricks workspace"
  type        = bool
  default     = false
}

variable "vnet_id" {
  description = "Virtual network resource ID"
  type        = string
  default     = ""
}

variable "public_subnet_name" {
  description = "Public subnet name"
  type        = string
  default     = ""
}

variable "private_subnet_name" {
  description = "Private subnet name"
  type        = string
  default     = ""
}

variable "public_subnet_nsg_association_id" {
  description = "Public subnet NSG association ID"
  type        = string
  default     = ""
}

variable "private_subnet_nsg_association_id" {
  description = "Private subnet NSG association ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}