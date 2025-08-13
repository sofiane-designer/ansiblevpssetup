# Requirements Document

## Introduction

This feature focuses on improving the existing Ansible VPS Setup playbook by addressing minor issues and implementing DevOps best practices. The improvements will enhance reliability, maintainability, and robustness of the playbook while maintaining its current functionality.

## Requirements

### Requirement 1

**User Story:** As a DevOps engineer, I want the Docker Compose version to be dynamically fetched instead of hardcoded, so that the playbook always installs the latest stable version without manual updates.

#### Acceptance Criteria

1. WHEN the Docker role executes THEN the system SHALL fetch the latest Docker Compose version from GitHub API
2. IF the GitHub API is unavailable THEN the system SHALL fallback to a known stable version
3. WHEN fetching the version THEN the system SHALL cache the result to avoid repeated API calls during the same playbook run

### Requirement 2

**User Story:** As a DevOps engineer, I want robust package manager detection that handles edge cases, so that the playbook works reliably across different Linux distributions and versions.

#### Acceptance Criteria

1. WHEN detecting package managers THEN the system SHALL handle Amazon Linux, Oracle Linux, and other RHEL derivatives
2. IF the distribution is unknown THEN the system SHALL attempt to detect available package managers directly
3. WHEN package manager detection fails THEN the system SHALL provide clear error messages with suggested manual configuration

### Requirement 3

**User Story:** As a DevOps engineer, I want network operations to have retry logic and error handling, so that temporary network issues don't cause playbook failures.

#### Acceptance Criteria

1. WHEN downloading files from external sources THEN the system SHALL retry up to 3 times with exponential backoff
2. IF all retries fail THEN the system SHALL provide clear error messages indicating the failure reason
3. WHEN network timeouts occur THEN the system SHALL wait progressively longer between retries (5s, 10s, 20s)

### Requirement 4

**User Story:** As a DevOps engineer, I want the playbook to use tags for selective execution, so that I can run specific parts of the provisioning process without executing everything.

#### Acceptance Criteria

1. WHEN running the playbook THEN users SHALL be able to use tags like 'common', 'docker', 'tailscale', 'admin'
2. WHEN using tags THEN the system SHALL execute only the tasks associated with those tags
3. WHEN no tags are specified THEN the system SHALL execute all tasks as before

### Requirement 5

**User Story:** As a DevOps engineer, I want handlers for service management, so that services are restarted only when configuration changes occur.

#### Acceptance Criteria

1. WHEN configuration files change THEN the system SHALL notify appropriate handlers
2. WHEN handlers are triggered THEN services SHALL be restarted only once at the end of the play
3. WHEN multiple tasks modify the same service THEN the handler SHALL run only once

### Requirement 6

**User Story:** As a DevOps engineer, I want validation tasks to verify system state after changes, so that I can ensure the playbook completed successfully.

#### Acceptance Criteria

1. WHEN services are installed THEN the system SHALL verify they are running and enabled
2. WHEN users are created THEN the system SHALL verify they can authenticate and have correct permissions
3. WHEN packages are installed THEN the system SHALL verify they are accessible and functional

### Requirement 7

**User Story:** As a DevOps engineer, I want backup tasks for critical configuration files, so that I can restore the system if something goes wrong.

#### Acceptance Criteria

1. WHEN modifying system configuration files THEN the system SHALL create timestamped backups
2. WHEN backups are created THEN they SHALL be stored in a consistent location (/var/backups/ansible/)
3. WHEN backup directory doesn't exist THEN the system SHALL create it with appropriate permissions