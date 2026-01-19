# Inventory Configuration

This directory contains Ansible inventory files that define your infrastructure.

## Files

- **sample_inventory.yml** - Sample inventory with different host types and groups

## Inventory Structure

The sample inventory defines 4 groups of Ubuntu servers:

### 1. `common_ubuntu` - Common Servers
Basic Ubuntu servers with essentials only.
- **Roles**: APT, Packages, Users, SSH, Timezone, Hostname, Firewall, Mail, Updates, Security, Monitoring
- **No**: Docker, Rundeck
- **Use Case**: Database servers, file servers, utility servers

```yaml
common-01:
  ansible_host: 192.168.1.100
common-02:
  ansible_host: 192.168.1.101
```

### 2. `docker_hosts` - Docker Servers
Ubuntu servers with Docker and container support.
- **Roles**: Essentials + Docker CE + Docker Compose
- **No**: Rundeck
- **Use Case**: Container platforms, microservices, application servers

```yaml
docker-01:
  ansible_host: 192.168.1.110
  docker_users: [ansible, John]
docker-02:
  ansible_host: 192.168.1.111
```

### 3. `rundeck_hosts` - Rundeck Orchestration Servers
Ubuntu servers with Rundeck for job orchestration.
- **Roles**: Essentials + Rundeck
- **No**: Docker
- **Use Case**: Automation platform, job orchestration, runbook execution

```yaml
rundeck-01:
  ansible_host: 192.168.1.120
  rundeck_port: 4440
rundeck-02:
  ansible_host: 192.168.1.121
```

### 4. `ubuntu_desktop` - Desktop Workstations
Ubuntu desktop workstations for users.
- **Roles**: Essentials + Docker (for local development)
- **No**: Rundeck
- **Use Case**: Developer machines, workstations

```yaml
desktop-01:
  ansible_host: 192.168.1.200
  desktop_user: John
desktop-02:
  ansible_host: 192.168.1.201
  desktop_user: alice
```

## Key Design Principles

### Docker & Rundeck Separation
- **Docker** and **Rundeck** do **NOT** run on the same host
- Docker hosts (`docker_hosts`, `ubuntu_desktop`) have Docker installed
- Rundeck hosts (`rundeck_hosts`) have Rundeck installed
- Common servers have neither

### Conditional Role Execution
The `site.yml` playbook uses conditionals to apply roles based on group membership:
```yaml
- role: docker
  when: inventory_hostname in groups.get('docker_hosts', []) or inventory_hostname in groups.get('ubuntu_desktop', [])
- role: rundeck
  when: inventory_hostname in groups.get('rundeck_hosts', [])
```

### Group-Specific Playbooks
For clearer execution, use group-specific playbooks:
- `common-hosts.yml` - Deploy to common servers
- `docker-hosts.yml` - Deploy to Docker servers
- `rundeck-hosts.yml` - Deploy to Rundeck servers
- `desktop-hosts.yml` - Deploy to desktops

## Usage

### Test Connectivity
```bash
# All hosts
ansible all -i inventory/sample_inventory.yml -m ping

# Specific group
ansible docker_hosts -i inventory/sample_inventory.yml -m ping

# Specific host
ansible docker-01 -i inventory/sample_inventory.yml -m ping
```

### Deploy via Group
```bash
# Deploy to all hosts with conditionals
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml

# Deploy to common servers only
ansible-playbook playbooks/common-hosts.yml -i inventory/sample_inventory.yml

# Deploy to docker hosts only
ansible-playbook playbooks/docker-hosts.yml -i inventory/sample_inventory.yml

# Deploy to rundeck hosts only
ansible-playbook playbooks/rundeck-hosts.yml -i inventory/sample_inventory.yml

# Deploy to desktops only
ansible-playbook playbooks/desktop-hosts.yml -i inventory/sample_inventory.yml
```

### Deploy Specific Roles
```bash
# Docker role on docker hosts only
ansible-playbook playbooks/docker-hosts.yml -i inventory/sample_inventory.yml --tags=docker

# SSH hardening everywhere
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml --tags=ssh

# Rundeck on rundeck hosts only
ansible-playbook playbooks/rundeck-hosts.yml -i inventory/sample_inventory.yml --tags=rundeck
```

### Test Run (Dry Run)
```bash
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml --check
```

### View Inventory
```bash
# List all hosts
ansible-inventory -i inventory/sample_inventory.yml --list

# List hosts in a group
ansible-inventory -i inventory/sample_inventory.yml --list | jq '.docker_hosts'

# Get host details
ansible-inventory -i inventory/sample_inventory.yml --host docker-01
```

## Customization

### Adding Hosts
Edit `sample_inventory.yml` and add new hosts under appropriate groups:

```yaml
docker_hosts:
  hosts:
    docker-03:
      ansible_host: 192.168.1.112
      ansible_user: ansible
      docker_users: [ansible]
```

### Changing IP Addresses
Update the `ansible_host` values to match your network:
```yaml
docker-01:
  ansible_host: 192.168.1.110  # Change this
```

### Adding Group Variables
Create group-specific variable files:
```
group_vars/
  docker_hosts.yml        # Variables for docker hosts
  rundeck_hosts.yml       # Variables for rundeck hosts
  common_ubuntu.yml       # Variables for common hosts
  all.yml                 # Variables for all hosts
  vault.yml               # Encrypted sensitive data
```

## Security Notes

1. **SSH Keys**: Uses SSH key authentication (no passwords)
2. **Ansible User**: Created by `user_accounts` role with passwordless sudo
3. **Vault**: Encrypt sensitive data with `ansible-vault`
4. **Network**: Update IP addresses to match your environment
5. **Firewall**: Configure firewall rules in `group_vars/all.yml`

## Default Ansible Variables

All hosts use these defaults from `group_vars/all.yml`:

```yaml
ansible_python_interpreter: /usr/bin/python3
ansible_connection: ssh
ansible_become: true
ansible_become_method: sudo
```

## Example: Complete Deployment

```bash
# 1. Update inventory with your IPs and hostnames
nano inventory/sample_inventory.yml

# 2. Add your SSH public key
nano group_vars/users.yml

# 3. Encrypt vault file
ansible-vault encrypt group_vars/vault.yml

# 4. Test connectivity
ansible all -i inventory/sample_inventory.yml -m ping

# 5. Deploy to common hosts first
ansible-playbook playbooks/common-hosts.yml -i inventory/sample_inventory.yml --ask-vault-pass

# 6. Deploy docker hosts
ansible-playbook playbooks/docker-hosts.yml -i inventory/sample_inventory.yml --ask-vault-pass

# 7. Deploy rundeck hosts
ansible-playbook playbooks/rundeck-hosts.yml -i inventory/sample_inventory.yml --ask-vault-pass

# 8. Deploy desktops
ansible-playbook playbooks/desktop-hosts.yml -i inventory/sample_inventory.yml --ask-vault-pass
```

## Troubleshooting

### Connection Issues
```bash
# Test SSH connection
ssh -i /path/to/key ansible@192.168.1.100

# Test with Ansible
ansible docker-01 -i inventory/sample_inventory.yml -m setup
```

### Missing Groups
If Ansible complains about missing groups, check:
1. Group names match between inventory and playbook
2. Host is assigned to at least one group
3. Inventory file syntax is valid: `ansible-inventory -i inventory/sample_inventory.yml`

### Role Not Running
If a role doesn't run, check:
1. Host is in the correct group
2. Tags match (if using `--tags`)
3. Conditional statements in playbook (see `site.yml`)

