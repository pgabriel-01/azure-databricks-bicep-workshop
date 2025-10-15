// Staging Environment Parameters
// This file contains parameter values specific to the staging environment

using '../main.bicep'

param environment = 'staging'
param location = 'East US'
param projectName = 'databricks-workshop'
param owner = 'staging-team'
param costCenter = 'staging'

// Databricks configuration for staging
param databricksSku = 'premium'
param noPublicIp = true

// Storage configuration
param storageAccountTier = 'Standard'
param storageReplicationType = 'GRS'

// Monitoring configuration
param logRetentionDays = 90

// Security configuration
param keyVaultSku = 'standard'
