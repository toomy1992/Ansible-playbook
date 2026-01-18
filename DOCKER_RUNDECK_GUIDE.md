# Docker and Rundeck Setup Guide

## Overview

This guide covers the configuration and usage of the Docker and Rundeck roles.

## Docker Role

### Installation

The Docker role automates the complete installation and configuration of Docker on Ubuntu/Debian systems.

### Features

- Official Docker repository setup
- Docker CE, Docker CLI, and containerd installation
- Docker Compose installation (latest version)
- Service enablement and startup
- Docker group creation and user management
- Daemon configuration (logging, live restore)

### Configuration

Add to `group_vars/all.yml`:

```yaml
# Docker users to add to docker group
docker_users:
  - ansible
  - ubuntu

# Docker daemon logging
docker_log_driver: json-file
docker_log_max_size: 10m
docker_log_max_file: 3

# Docker daemon features
docker_live_restore: true
docker_userland_proxy: false

# Install Docker Compose
docker_compose_install: true
```

### Usage

#### Basic Installation

```bash
# Install Docker only
ansible-playbook playbooks/site.yml --tags=docker
```

#### With Users

```yaml
# group_vars/all.yml
docker_users:
  - ansible
  - myuser
```

```bash
ansible-playbook playbooks/site.yml --tags=docker
```

#### Verify Installation

```bash
# On remote host
docker --version
docker-compose --version
docker run hello-world
```

### Default Values

```yaml
docker_users: []
docker_log_driver: json-file
docker_log_max_size: 10m
docker_log_max_file: 3
docker_live_restore: true
docker_userland_proxy: false
docker_compose_install: true
```

---

## Rundeck Role

### Installation

The Rundeck role installs and configures Rundeck from official Debian repositories. Supports Focal (Ubuntu 20.04) and compatible systems.

### Features

- OpenJDK 11 installation (required)
- Official Rundeck repository setup
- Rundeck service installation
- Server configuration (port, URL, context path)
- Framework properties configuration
- User authentication setup
- SSH key generation
- Service enablement and verification

### Prerequisites

- Java 11 (installed automatically)
- Sufficient disk space (/var/rundeck, /var/log/rundeck)
- Port 4440 available (default)

### Configuration

Add to `group_vars/all.yml`:

```yaml
# Rundeck server URL
rundeck_grails_url: http://localhost:4440

# Rundeck port and address
rundeck_port: 4440
rundeck_address: 127.0.0.1

# Context path
rundeck_context_path: /

# User authentication
rundeck_users:
  - username: admin
    password: "{{ vault_rundeck_admin_password }}"
  - username: developer
    password: "{{ vault_rundeck_dev_password }}"

# Generate SSH key for Rundeck
rundeck_ssh_key_generate: false
```

### Advanced Configuration

#### Access from Network

```yaml
# Allow network access
rundeck_address: 0.0.0.0
rundeck_grails_url: http://your-server.example.com:4440
```

#### HTTPS Setup (with proxy)

```yaml
# Configure Rundeck for HTTPS behind proxy
rundeck_grails_url: https://rundeck.example.com
rundeck_context_path: /rundeck
```

#### User Management

```yaml
rundeck_users:
  - username: admin
    password: "{{ vault_admin_password }}"
  - username: operator
    password: "{{ vault_operator_password }}"
  - username: viewer
    password: "{{ vault_viewer_password }}"
```

#### SSH Key Generation

```yaml
# Generate SSH key for Rundeck (for remote job execution)
rundeck_ssh_key_generate: true
```

This creates `/var/lib/rundeck/.ssh/id_rsa` for Rundeck to use for SSH-based job execution.

### Usage

#### Basic Installation

```bash
# Install Rundeck with defaults
ansible-playbook playbooks/apps.yml --tags=rundeck
```

#### With Custom Configuration

```bash
# Configure variables first
vim group_vars/all.yml
# Add rundeck configuration

# Install
ansible-playbook playbooks/apps.yml --tags=rundeck
```

#### Access Rundeck

After installation:

```
URL: http://localhost:4440 (default)
Default User: admin
Default Password: rundeck (from role defaults)
```

Change default password immediately!

#### Remote Execution

For job execution on remote hosts:

```bash
# Generate SSH key
ansible-playbook playbooks/apps.yml --tags=rundeck \
  -e "rundeck_ssh_key_generate=true"

# Retrieve public key
ansible all -m command -a "cat /var/lib/rundeck/.ssh/id_rsa.pub"

# Add to target hosts authorized_keys
ansible all -m authorized_key \
  -a "user=ansible key='{{ rundeck_pub_key }}' state=present"
```

### Default Values

```yaml
rundeck_grails_url: http://localhost:4440
rundeck_port: 4440
rundeck_address: 127.0.0.1
rundeck_context_path: /
rundeck_server_name: rundeck-server
rundeck_users: []
rundeck_ssh_key_generate: false
rundeck_execution_mode: active
rundeck_loglevel: INFO
```

### Project Setup

Create Rundeck projects via API:

```bash
# List projects
curl -H "X-Rundeck-Auth-Token: <token>" \
  http://localhost:4440/api/1/projects

# Create project
curl -X POST -H "X-Rundeck-Auth-Token: <token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"my-project","description":"My Project"}' \
  http://localhost:4440/api/1/projects
```

### Security Considerations

- **Change Default Password:** Immediately change admin password
- **API Tokens:** Create API tokens for integrations
- **SSH Keys:** Secure Rundeck SSH keys (stored in /var/lib/rundeck/.ssh)
- **Network Access:** Use firewall rules to restrict Rundeck access
- **HTTPS:** Consider running behind NGINX with SSL/TLS
- **Backups:** Regular backups of /etc/rundeck and /var/rundeck

### Troubleshooting

#### Port 4440 Not Accessible

```bash
# Check service status
systemctl status rundeckd

# Check port
netstat -tuln | grep 4440

# Check firewall
sudo ufw status | grep 4440
```

#### Logs

```bash
# Rundeck logs
tail -f /var/log/rundeck/rundeck.log

# Startup issues
journalctl -u rundeckd -n 50
```

#### Verify Installation

```bash
# Check API endpoint
curl http://localhost:4440/api/1/system/info

# Check Java
java -version

# Check Rundeck user
id rundeck
```

### Integration with Docker

Run Rundeck in Docker:

```bash
# After Docker installation
docker run -d \
  -p 4440:4440 \
  -e RUNDECK_GRAILS_URL=http://localhost:4440 \
  -v rundeck-etc:/etc/rundeck \
  -v rundeck-var:/var/rundeck \
  --name rundeck \
  rundeckpro/rundeck:latest
```

---

## Combined Setup

Install everything (essentials + apps):

```bash
# Step 1: Configure inventory and variables
vim inventory/hosts
vim group_vars/all.yml

# Step 2: Install essentials
ansible-playbook playbooks/site.yml --check
ansible-playbook playbooks/site.yml

# Step 3: Install Docker and Rundeck
ansible-playbook playbooks/apps.yml --check
ansible-playbook playbooks/apps.yml

# Step 4: Verify installation
ansible-playbook playbooks/diagnostic.yml
```

---

## Documentation References

- [Docker Docs](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Rundeck Docs](https://docs.rundeck.com/)
- [Rundeck Installation](https://docs.rundeck.com/docs/administration/install/)
- [Rundeck API](https://docs.rundeck.com/docs/api/)

---

## Support

For issues:
1. Check role defaults in `roles/docker/defaults/main.yml` and `roles/rundeck/defaults/main.yml`
2. Review logs on target host
3. Enable verbose mode: `ansible-playbook -vvv`
4. Check firewall rules: `ufw status`
