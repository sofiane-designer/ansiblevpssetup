# Ansible VPS Setup

[![CI](https://github.com/sofiane-designer/ansiblevpssetup/actions/workflows/lint.yml/badge.svg)](https://github.com/sofiane-designer/ansiblevpssetup/actions/workflows/lint.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Ansible >= 2.14](https://img.shields.io/badge/Ansible-%E2%89%A5%202.14-blue)

Ansible VPS Setup is an opinionated, production‑ready Ansible playbook that provisions and hardens fresh Linux VPS hosts in minutes. It establishes a secure, sane baseline, creates an administrative user with SSH key–based access, and — when enabled — installs Docker Engine and Docker Compose v2 with built‑in verification and smoke tests. You can also join hosts to your Tailscale mesh (including exit‑node and subnet routes) and export a machine‑readable view of your network.

Highlights:
- Upgrade system packages and install a curated set of essentials
- Create an admin user with SSH key–only access and sudo privileges
- Optional Docker Engine + Compose v2 with dynamic versioning and verification
- Optional Tailscale setup with exit‑node and routes support
- **NEW:** Comprehensive tagging system for selective execution
- **NEW:** Handler-based service management and validation framework
- **NEW:** Backup system with automated cleanup
- **NEW:** Network retry logic and enhanced error handling
- Emit a consolidated Tailscale inventory JSON for downstream tooling
- Idempotent, minimal assumptions, easy to override via group_vars/all.yml

Table of contents
- Overview
- Use Cases
- Folder Structure
- Prerequisites
- Inventory
- Configuration Highlights
- Variables and Feature Flags
- Gating Behavior (Docker/Compose)
- Quick Start
- Tailscale + Vault
- Role Details
- Outputs
- Security Notes
- Troubleshooting
- Common Commands
- Development
- License

Overview
- site.yml: main playbook
- ansible.cfg: opinionated defaults (inventory path, sudo, output formatting)
- group_vars/all.yml: global defaults and feature flags
- inventory/: example inventories (INI and YAML)
- roles/
  - common: upgrades + base packages
  - admin_user: user + SSH + sudoers
  - docker: Docker Engine + Compose v2 + optional tests
  - tailscale: install + configure + facts
- collections/requirements.yml: collection dependencies

Folder Structure

```text
ansiblevpssetup/
├─ .github/
│  └─ workflows/
│     └─ lint.yml                 # CI: yamllint + ansible-lint
├─ collections/
│  └─ requirements.yml            # Ansible collections dependencies
├─ group_vars/
│  └─ all.yml                     # Global defaults and feature flags
├─ inventory/
│  ├─ hosts.ini                   # Default inventory (set in ansible.cfg)
│  └─ hosts.yml                   # Alternative YAML inventory
├─ roles/
│  ├─ admin_user/
│  │  └─ tasks/
│  │     └─ main.yml              # Create admin user, SSH, sudoers
│  ├─ common/
│  │  └─ tasks/
│  │     └─ main.yml              # Updates, base packages
│  ├─ docker/
│  │  └─ tasks/
│  │     └─ main.yml              # Docker Engine + Compose + gating/tests
│  └─ tailscale/
│     └─ tasks/
│        └─ main.yml              # Tailscale install/config + facts
├─ .gitignore
├─ LICENSE
├─ README.md
├─ ansible.cfg                    # Opinionated defaults
└─ site.yml                       # Main playbook

# Generated after runs (not committed):
# tailscale_inventory.json
```

Prerequisites (Control Node)
- Ansible 2.14+ (or newer)
- Python 3 on the control node
- Install required collections:
  
  ```bash
  ansible-galaxy collection install -r collections/requirements.yml
  ```

Inventory
- Default inventory used is inventory/hosts.ini (defined in ansible.cfg). To use the YAML inventory instead, pass -i inventory/hosts.yml.

Example inventory/hosts.ini:

```ini
[all]
server1 ansible_host=203.0.113.10 ansible_user=root
server2 ansible_host=203.0.113.11 ansible_user=root
```

Configuration Highlights (ansible.cfg)
- inventory = inventory/hosts.ini: default inventory file
- roles_path = roles: roles are resolved under ./roles
- interpreter_python = auto_silent: auto-detect Python on managed hosts quietly
- retry_files_enabled = False: no .retry files
- host_key_checking = False: skip SSH host key verification (convenient but less secure)
- stdout_callback = yaml and bin_ansible_callbacks = True: readable, timed output
- become defaults: sudo enabled by default, no prompt (requires passwordless sudo)

Variables and Feature Flags
Defined in group_vars/all.yml (override per-host/group/inventory or via -e "key=value"). Key flags:
- install_docker: boolean
  - If true, install Docker and enable the service.
- install_docker_compose: boolean
  - If true, install Docker Compose v2 plugin.
- docker_verify_installation: boolean
  - If true, run docker --version to verify.
- docker_run_hello_world_test: boolean
  - If true, run docker run --rm hello-world.
- docker_compose_test: boolean
  - If true, run a minimal docker compose up/down test.
- install_tailscale: boolean
  - If true, install and configure Tailscale.
- tailscale_* flags: control exit-node, routes, SSH, etc.

Gating Behavior (Docker/Compose)
- The docker role detects whether Docker and Compose are already present.
- Verify/tests only run when their flags are true AND Docker/Compose are either:
  - being installed in this run (install_docker/install_docker_compose true), or
  - already present on the host.
- If install_docker is false and Docker is absent, verify/tests are skipped.

Quick Start
1) Install required collections
   
   ```bash
   ansible-galaxy collection install -r collections/requirements.yml
   ```

2) Verify connectivity to your hosts
   
   ```bash
   ansible all -m ping
   ```

3) Provision base system and admin user (no Docker/Tailscale)
   
   ```bash
   ansible-playbook site.yml
   ```

4) Provision with Docker enabled
   
   ```bash
   ansible-playbook site.yml -e install_docker=true
   ```

5) Provision with Docker and Tailscale (prompts for vault password)
   
   ```bash
   ansible-playbook site.yml -e install_docker=true -e install_tailscale=true --ask-vault-pass
   ```

Tips
- Use YAML inventory instead of INI:
  
  ```bash
  ansible-playbook -i inventory/hosts.yml site.yml
  ```
- Limit to specific hosts:
  
  ```bash
  ansible-playbook -l server1,server2 site.yml
  ```
- Override variables at runtime:
  
  ```bash
  ansible-playbook site.yml -e install_docker=true -e docker_compose_test=false
  ```

Tailscale Authentication via Ansible Vault
- Create a vault file containing your key:
  
  ```bash
  echo "vault_tailscale_auth_key: 'tskey-XXXXXXXXXXXXXXXX'" > group_vars/vault.yml
  ```
- Encrypt it:
  
  ```bash
  ansible-vault encrypt group_vars/vault.yml
  ```
- group_vars/all.yml references tailscale_auth_key: `{{ vault_tailscale_auth_key | default('') }}`
- Run with `--ask-vault-pass` or `--vault-password-file` to decrypt.

Role Details
- common: updates package cache, upgrades system, installs packages from essential_packages (curl, python3, vim, git by default)
- admin_user: creates admin user (admin_username), installs your local public key (local_ssh_public_key_path), configures sudoers
- docker:
  - Detects docker and docker compose presence
  - Installs Docker via get.docker.com when install_docker=true
  - Installs Compose v2 plugin when install_docker_compose=true
  - Optional verification/tests gated as described
- tailscale: installs tailscale, sets sysctls as needed, tailscale up with flags, collects node details into host facts

Outputs
- tailscale_inventory.json is generated at the project root after a run, consolidating per-host Tailscale data (IPv4/IPv6/hostnames).

Security Notes
- host_key_checking is disabled in ansible.cfg for convenience. Consider enabling it in production and managing known_hosts.
- become_ask_pass is false; configure passwordless sudo for the remote user or run with --ask-become-pass when required.
- Store secrets (like Tailscale auth keys) only in encrypted vault files. Never commit plaintext credentials.

Troubleshooting
- SSH host key prompts or failures:
  - Either enable host_key_checking and pre-populate known_hosts (e.g., ssh-keyscan), or keep it disabled as provided.
- Sudo failures (askpass needed):
  - Configure the remote user with NOPASSWD sudo, or run with --ask-become-pass.
- Docker tasks skipped unexpectedly:
  - Check install_docker and detection: if Docker isn’t installed and install_docker=false, verify/tests are skipped by design.
- Compose binary architecture mismatch:
  - The role downloads a platform-specific binary; ensure ansible_architecture and ansible_system facts match your target.

Common Commands
- Use INI inventory (default):
  
  ```bash
  ansible-playbook site.yml
  ```
- Use YAML inventory:
  
  ```bash
  ansible-playbook -i inventory/hosts.yml site.yml
  ```
- Limit to specific hosts:
  
  ```bash
  ansible-playbook -l server1,server2 site.yml
  ```
- Override variables at runtime:
  
  ```bash
  ansible-playbook site.yml -e install_docker=true -e docker_compose_test=false
  ```

Development
- Linting (if you use ansible-lint):
  
  ```bash
  ansible-lint
  ```
- Dry run / check mode:
  
  ```bash
  ansible-playbook site.yml --check
  ```
- Diff changes:
  
  ```bash
  ansible-playbook site.yml --diff
  ```

License
- MIT — see LICENSE

Contributions
- Issues and PRs welcome. Please include details about OS/distro versions and your inventory/vars when reporting problems.
