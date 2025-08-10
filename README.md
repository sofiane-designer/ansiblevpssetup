# Ansible VPS Setup

Provision and harden Linux VPS hosts with a single playbook. This repo:
- Installs system updates and essential packages
- Creates an admin user with SSH key-based access and sudo
- Optionally installs Docker Engine and Docker Compose v2 with safe verification and smoke tests
- Optionally installs and configures Tailscale (with exit-node and routes support)
- Emits a consolidated Tailscale inventory JSON for easy consumption

Contents
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

Prerequisites (control node)
- Ansible 2.14+ (or newer)
- Python 3 on the control node
- Install required collections:
  ansible-galaxy collection install -r collections/requirements.yml

Inventory
- Default inventory used is inventory/hosts.ini (defined in ansible.cfg). To use the YAML inventory instead, pass -i inventory/hosts.yml.

Example inventory/hosts.ini:
[all]
server1 ansible_host=203.0.113.10 ansible_user=root
server2 ansible_host=203.0.113.11 ansible_user=root

Configuration (ansible.cfg highlights)
- inventory = inventory/hosts.ini: default inventory file
- roles_path = roles: roles are resolved under ./roles
- interpreter_python = auto_silent: auto-detect Python on managed hosts quietly
- retry_files_enabled = False: no .retry files
- host_key_checking = False: skip SSH host key verification (convenient but less secure)
- stdout_callback = yaml and bin_ansible_callbacks = True: readable, timed output
- become defaults: sudo enabled by default, no prompt (requires passwordless sudo)

Variables and feature flags
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

Important gating behavior (Docker/Compose)
- The docker role now detects whether Docker and Compose are already present.
- Verify/tests only run when their flags are true AND Docker/Compose are either:
  - being installed in this run (install_docker/install_docker_compose true), or
  - already present on the host.
- If install_docker is false and Docker is absent, verify/tests are skipped.

Quick start
1) Install collections:
   ansible-galaxy collection install -r collections/requirements.yml
2) Confirm you can connect to hosts:
   ansible all -m ping
3) Provision base and admin user only (no Docker/Tailscale):
   ansible-playbook site.yml
4) Provision with Docker:
   ansible-playbook site.yml -e install_docker=true
5) Provision with Docker and Tailscale (with vault password prompt):
   ansible-playbook site.yml -e install_docker=true -e install_tailscale=true --ask-vault-pass

Tailscale authentication via Ansible Vault
- Create a vault file containing your key:
  echo "vault_tailscale_auth_key: 'tskey-XXXXXXXXXXXXXXXX'" > group_vars/vault.yml
- Encrypt it:
  ansible-vault encrypt group_vars/vault.yml
- group_vars/all.yml references tailscale_auth_key: "{{ vault_tailscale_auth_key | default('') }}"
- Run with --ask-vault-pass or --vault-password-file to decrypt.

Role details
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

Security notes
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

Common commands
- Use INI inventory (default):
  ansible-playbook site.yml
- Use YAML inventory:
  ansible-playbook -i inventory/hosts.yml site.yml
- Limit to specific hosts:
  ansible-playbook -l server1,server2 site.yml
- Override variables at runtime:
  ansible-playbook site.yml -e install_docker=true -e docker_compose_test=false

Development
- Linting (if you use ansible-lint):
  ansible-lint
- Dry run / check mode:
  ansible-playbook site.yml --check
- Diff changes:
  ansible-playbook site.yml --diff

License
- MIT (or your preferred license). Add a LICENSE file if you want to formalize it.

Contributions
- Issues and PRs welcome. Please include details about OS/distro versions and your inventory/vars when reporting problems.
