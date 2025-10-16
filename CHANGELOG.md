# Changelog

All notable changes to the Azure Databricks Bicep Workshop will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

*No unreleased changes*

## [1.1.3] - 2024-10-15

### Changed
- **Databricks Naming**: Optimized workspace naming for better consistency
- **Resource Names**: Shortened managed resource group name from `databricks-managed-rg` to `managed-rg`
- **Workspace Naming**: Simplified workspace name from `databricks` suffix to `db` suffix
- **Portal Navigation**: Improved Azure portal navigation with more concise resource names

### Maintained
- Full compatibility with existing parameter files
- All functional capabilities preserved
- No breaking changes to deployment process

## [1.1.2] - 2024-10-15

### Removed
- **Redundant Files**: Removed `bicep-comparison/` directory (superseded by `BICEP_VS_TERRAFORM_COMPLETE.md`)
- **Debug Artifacts**: Cleaned up OIDC authentication timestamp artifacts
- **Outdated References**: Removed references to non-existent Slack workspace

### Changed
- **README Structure**: Updated project structure to reflect current organization
- **Documentation**: Streamlined learning resources section for clarity
- **Repository Organization**: Cleaner structure for professional workshop delivery

### Fixed
- **Broken References**: Fixed outdated links and directory references
- **Project Structure**: Updated documentation to match actual file organization

## [1.1.1] - 2024-10-15

### Fixed
- **Storage Account Naming**: Improved global uniqueness to prevent workshop conflicts
- **Naming Strategy**: Use subscription ID + resource group ID + deployment name for uniqueness
- **Workshop Safety**: Prevents naming conflicts when multiple participants deploy simultaneously
- **Cross-Subscription**: Works reliably across different Azure subscriptions

### Changed
- **Unique Identifier**: Enhanced from `uniqueString(resourceGroup().id)` to `uniqueString(subscription().subscriptionId, resourceGroup().id, deployment().name)`
- **Fallback Naming**: Updated from `dataworkshop` to `workshop` for consistency
- **Comments**: Added explanatory comments about uniqueness strategy

## [1.1.0] - 2024-10-15

### Added
- **Complete Terraform Implementation**: Full equivalent infrastructure in `terraform-comparison/`
- **Bicep vs Terraform Comparison**: Comprehensive analysis in `BICEP_VS_TERRAFORM_COMPLETE.md`
- **Feature Matrix**: Detailed comparison of Bicep vs Terraform capabilities
- **Working Examples**: Deployable code for both Bicep and Terraform approaches
- **Decision Framework**: Practical guidance for choosing between tools

### Enhanced
- **Workshop Educational Value**: Now provides hands-on comparison between tools
- **Real-World Relevance**: Industry-standard approach to tool evaluation
- **Practical Experience**: Participants can deploy with both Bicep and Terraform

### Documentation
- **Deployment Instructions**: Complete setup guides for both tools
- **Comparison Matrix**: Objective feature analysis
- **Migration Scenarios**: When to choose which approach

## [1.0.3] - 2024-10-15

### Changed
- **Documentation Polish**: Improved formatting for professional corporate presentation
- **Accessibility**: Enhanced compatibility with screen readers and assistive technologies
- **Print Compatibility**: Improved documentation printing without special characters
- **Corporate Standards**: Achieved professional documentation style for enterprise environments

### Maintained
- All functional content and instructions preserved
- Section structure and hierarchy unchanged
- Workshop delivery quality maintained

## [1.0.2] - 2024-10-15

### Fixed
- **Repository Clone URL**: Corrected to actual `pgabriel-01/azure-databricks-bicep-workshop`
- **Resource Group Names**: Fixed to correct `rg-databricks-dev` naming pattern
- **Azure CLI Commands**: Updated deployment syntax to working commands
- **Content Focus**: Replaced inappropriate Terraform content with Bicep-specific guidance
- **Setup Instructions**: Removed references to non-existent setup scripts

### Added
- **Production Ready Badge**: Clear indication of tested, validated workshop status
- **Comprehensive Cleanup Section**: Detailed destroy instructions with cost warnings
- **GitHub Actions Guidance**: Recommended workflow usage for deploy and destroy
- **Cost Management Warnings**: Prominent cleanup reminders to prevent ongoing charges

### Improved
- **Quick Start Flow**: Now emphasizes tested GitHub Actions approach
- **Workshop Modules**: Updated to reflect destroy functionality testing
- **CI/CD Documentation**: Accurate reflection of actual Bicep pipeline capabilities
- **User Experience**: Clear distinction between automated and manual approaches

## [1.0.1] - 2024-10-15

### Tested
- **Deploy Functionality**: Successfully tested complete infrastructure deployment
- **Destroy Functionality**: Successfully tested complete infrastructure cleanup
- **CI/CD Pipeline**: End-to-end workflow validation completed
- **Cost Management**: Verified proper resource cleanup prevents ongoing charges

### Documentation
- Updated CHANGELOG.md with proper release documentation
- Confirmed all features work as documented

## [1.0.0] - 2024-10-15

### Added
- Comprehensive troubleshooting guide (`docs/troubleshooting.md`)
- MIT License for open educational use
- Comprehensive validation checklist (`docs/validation-checklist.md`) 
- CHANGELOG.md for change tracking

### Fixed
- Corrected README.md directory structure to match actual repository layout
- Fixed broken link to troubleshooting guide in README
- Updated project structure documentation accuracy
- Removed broken links to non-existent documentation files

### Changed
- Improved README.md project structure section with accurate file listings
- Enhanced documentation organization and clarity
- Organized documentation section into logical categories
- Improved README.md project structure section with accurate file listings
- Enhanced documentation organization and clarity

## [1.0.0] - 2024-01-XX

### Added
- Initial Azure Databricks Bicep Workshop repository
- Modular Bicep infrastructure templates
- Azure Databricks workspace deployment automation
- GitHub Actions CI/CD pipeline (`bicep.yml`)
- Comprehensive documentation structure
- Workshop setup and configuration guides
- Sample datasets and processing examples
- Terraform vs Bicep comparison materials
- Security and governance best practices

### Infrastructure Components
- Resource group management
- Virtual network with subnet configuration
- Network Security Groups (NSG) with proper rules
- Azure Databricks workspace with VNet injection
- Storage account for data processing
- Azure Key Vault for secrets management
- Modular Bicep template architecture

### Documentation
- Setup guide for workshop prerequisites
- Architecture overview and design decisions
- Best practices for Infrastructure as Code
- Troubleshooting common deployment issues
- Step-by-step workshop instructions

### CI/CD Pipeline
- Automated Bicep validation and deployment
- Multi-environment support (dev, staging, prod)
- Security scanning and compliance checks
- Automated testing and verification

---

## How to Read This Changelog

- **Added** for new features
- **Changed** for changes in existing functionality  
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes

## Version Guidelines

This workshop follows semantic versioning:
- **Major** (X.0.0): Breaking changes to workshop structure or major new sections
- **Minor** (0.X.0): New features, modules, or significant improvements
- **Patch** (0.0.X): Bug fixes, documentation updates, small improvements