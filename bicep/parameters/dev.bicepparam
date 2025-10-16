// Development Environment Parameters
// This file contains parameter values specific to the development environment

using '../main.bicep'

param environment = 'dev'
param location = 'East US 2'
param projectName = 'databricks-workshop'
param owner = 'dev-team'
param costCenter = 'development'

// Databricks configuration for development
param databricksSku = 'standard'
param noPublicIp = false

// Storage configuration
param storageAccountTier = 'Standard'
param storageReplicationType = 'LRS'

// Monitoring configuration
param logRetentionDays = 30

// Security configuration
param keyVaultSku = 'standard'
