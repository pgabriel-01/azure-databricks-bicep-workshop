# Networking Module Variables

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

variable "vnet_address_prefix" {
  description = "Virtual network address space"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_prefix" {
  description = "Public subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_prefix" {
  description = "Private subnet address prefix"
  type        = string
  default     = "10.0.2.0/24"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}