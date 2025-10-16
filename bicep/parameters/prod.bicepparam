// Production Environment Parameters
// This file contains parameter values specific to the production environment

using '../main.bicep'

param environment = 'prod'
param location = 'East US 2'
param projectName = 'databricks-workshop'
param owner = 'production-team'
param costCenter = 'production'

// Databricks configuration for production
param databricksSku = 'premium'
param noPublicIp = true

// Storage configuration
param storageAccountTier = 'Premium'
param storageReplicationType = 'GRS'

// Monitoring configuration
param logRetentionDays = 365

// Security configuration
param keyVaultSku = 'premium'
