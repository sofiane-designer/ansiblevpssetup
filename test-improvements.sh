#!/bin/bash
# Test script for Ansible playbook improvements

set -e

echo "=== Testing Ansible VPS Setup Improvements ==="

# Test 1: Package manager detection
echo "Testing package manager detection..."
ansible-playbook test-playbook.yml --tags test-common -v

# Test 2: Tag-based execution
echo "Testing tag-based execution..."
ansible-playbook site.yml --tags common --check -v

# Test 3: Docker version fetching
echo "Testing Docker Compose version fetching..."
ansible-playbook test-playbook.yml --tags test-docker -v

# Test 4: Backup functionality
echo "Testing backup functionality..."
ansible-playbook test-playbook.yml --tags test-backup -v

# Test 5: Validation tasks
echo "Testing validation tasks..."
ansible-playbook test-playbook.yml --tags test-validation -v

# Test 6: Cleanup
echo "Cleaning up test files..."
ansible-playbook test-playbook.yml --tags test-cleanup -v

echo "=== All tests completed successfully! ==="