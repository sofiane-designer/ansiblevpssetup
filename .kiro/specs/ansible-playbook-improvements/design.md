# Design Document

## Overview

This design document outlines the improvements to the Ansible VPS Setup playbook to address minor issues and implement DevOps best practices. The improvements focus on reliability, maintainability, and robustness while preserving the existing functionality and user experience.

## Architecture

The improvements will be implemented within the existing role-based architecture:

```
roles/
├── common/
│   ├── tasks/main.yml (enhanced package manager detection)
│   └── handlers/main.yml (new)
├── admin_user/
│   ├── tasks/main.yml (add validation and backup)
│   └── handlers/main.yml (new)
├── docker/
│   ├── tasks/main.yml (dynamic versioning, retries, validation)
│   └── handlers/main.yml (new)
└── tailscale/
    ├── tasks/main.yml (add retries and validation)
    └── handlers/main.yml (new)
```

## Components and Interfaces

### Dynamic Version Fetching Component

**Purpose:** Fetch latest Docker Compose version from GitHub API with fallback mechanism.

**Implementation:**
- Use `uri` module to query GitHub API: `https://api.github.com/repos/docker/compose/releases/latest`
- Parse JSON response to extract tag name
- Implement fallback to hardcoded version on API failure
- Cache result in ansible facts to avoid repeated calls

**Interface:**
```yaml
- name: Get latest Docker Compose version
  uri:
    url: https://api.github.com/repos/docker/compose/releases/latest
    method: GET
    return_content: yes
  register: compose_release
  failed_when: false
  
- name: Set Docker Compose version
  set_fact:
    docker_compose_version: "{{ compose_release.json.tag_name | default('v2.27.1') }}"
```

### Enhanced Package Manager Detection

**Purpose:** Robust detection of package managers across Linux distributions.

**Implementation:**
- Primary detection based on `ansible_facts.os_family`
- Secondary detection using `ansible_facts.distribution`
- Tertiary detection by checking for package manager binaries
- Clear error handling for unsupported distributions

**Logic Flow:**
1. Check OS family (Debian, RedHat, Suse, Arch)
2. For RedHat family, detect dnf vs yum based on version and availability
3. Handle special cases (Amazon Linux, Oracle Linux, etc.)
4. Fallback to binary detection if family-based detection fails

### Network Retry Component

**Purpose:** Add resilience to network operations with retry logic.

**Implementation:**
- Apply to all `get_url` and `uri` tasks
- Use exponential backoff: 5s, 10s, 20s
- Provide meaningful error messages
- Maintain idempotency

**Pattern:**
```yaml
- name: Download with retry
  get_url:
    url: "{{ item.url }}"
    dest: "{{ item.dest }}"
  retries: 3
  delay: 5
  register: download_result
  until: download_result is succeeded
```

### Tagging Strategy

**Tags Structure:**
- `common`: Base system updates and packages
- `admin`: Admin user creation and SSH setup
- `docker`: Docker and Docker Compose installation
- `tailscale`: Tailscale installation and configuration
- `validation`: All validation tasks
- `backup`: All backup tasks

### Handler System

**Purpose:** Efficient service management with change-triggered restarts.

**Handlers per role:**
- `common`: Package cache updates
- `admin_user`: SSH service restart
- `docker`: Docker service restart
- `tailscale`: Tailscale service restart

### Validation Framework

**Purpose:** Verify system state after changes.

**Validation Types:**
1. **Service Validation:** Check service status and enablement
2. **User Validation:** Verify user creation and permissions
3. **Package Validation:** Confirm package installation and functionality
4. **Network Validation:** Test connectivity and ports

### Backup System

**Purpose:** Create safety nets for configuration changes.

**Backup Strategy:**
- Backup location: `/var/backups/ansible/`
- Naming convention: `{filename}.{timestamp}.backup`
- Backup before modification
- Retention: Keep last 5 backups per file

## Data Models

### Version Information
```yaml
docker_compose_version_info:
  version: "v2.27.1"
  source: "api|fallback"
  fetched_at: "2024-01-15T10:30:00Z"
```

### Package Manager Facts
```yaml
package_manager_info:
  primary: "apt|dnf|yum|zypper|pacman"
  available_managers: ["apt", "snap"]
  detection_method: "os_family|binary|manual"
```

### Backup Metadata
```yaml
backup_info:
  original_file: "/etc/sudoers.d/ansible"
  backup_file: "/var/backups/ansible/sudoers.d_ansible.20240115_103000.backup"
  timestamp: "2024-01-15T10:30:00Z"
  checksum: "sha256:abc123..."
```

## Error Handling

### Network Failures
- Implement retry logic with exponential backoff
- Provide clear error messages indicating the specific failure
- Offer manual intervention steps in error messages
- Log all retry attempts for debugging

### Package Manager Issues
- Graceful degradation when preferred package manager unavailable
- Clear error messages for unsupported distributions
- Suggestions for manual configuration

### Service Failures
- Detailed error reporting for service start/enable failures
- Validation of service status before marking tasks complete
- Rollback procedures for critical service failures

### Permission Issues
- Validate permissions before attempting operations
- Clear error messages for insufficient privileges
- Suggestions for resolving permission issues

## Testing Strategy

### Unit Testing
- Test package manager detection logic with various OS combinations
- Test version fetching with mocked API responses
- Test backup and restore functionality

### Integration Testing
- Test complete playbook execution on multiple distributions
- Test network failure scenarios with simulated outages
- Test tag-based execution for all tag combinations

### Validation Testing
- Verify all validation tasks correctly identify issues
- Test handler triggering and execution
- Verify backup creation and restoration

### Performance Testing
- Measure impact of retry logic on execution time
- Test API rate limiting scenarios
- Verify caching effectiveness

## Security Considerations

### API Access
- GitHub API access doesn't require authentication for public repos
- Implement rate limiting awareness
- No sensitive data exposed in API calls

### Backup Security
- Backup files maintain original permissions
- Backup directory secured with appropriate permissions (750)
- No sensitive data logged during backup operations

### Network Security
- All downloads use HTTPS
- Verify checksums where available
- No credentials transmitted over network

## Implementation Phases

### Phase 1: Core Improvements
1. Dynamic Docker Compose versioning
2. Enhanced package manager detection
3. Network retry logic

### Phase 2: Operational Excellence
1. Tagging implementation
2. Handler system
3. Basic validation

### Phase 3: Safety and Monitoring
1. Backup system
2. Comprehensive validation
3. Enhanced error reporting

## Backward Compatibility

All improvements maintain backward compatibility:
- Existing variable names and defaults preserved
- No breaking changes to role interfaces
- Graceful degradation when new features unavailable
- Existing playbook execution patterns unchanged