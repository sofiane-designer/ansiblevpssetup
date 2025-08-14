# Changelog

All notable changes to this Ansible VPS Setup project will be documented in this file.

## [Unreleased]

### Added
- Enhanced package manager detection supporting apt, dnf, yum, zypper, and pacman
- Dynamic Docker Compose versioning with GitHub API integration
- Comprehensive tagging system with 20+ tags for selective execution
- Handler-based service management for efficient service restarts
- Backup system with automated cleanup for configuration files
- Validation framework for system state verification
- Network retry logic with exponential backoff for downloads
- System timezone configuration support
- Swap management functionality
- Docker daemon configuration with logging options
- Additional essential packages (htop, tree)

### Changed
- Improved error handling and logging throughout all roles
- Enhanced CI/CD pipeline with automated testing
- Updated documentation with new features

### Removed
- Security hardening components (as requested)
- Monitoring role components (as requested)
- yamllint configuration

## [1.0.0] - Initial Release

### Added
- Basic VPS provisioning with common packages
- Admin user creation with SSH key setup
- Docker and Docker Compose installation
- Tailscale VPN integration
- Basic inventory management