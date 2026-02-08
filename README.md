# Ansible Complete Infrastructure Framework

**Warning This Repo is in active development - it requires additional apps to to be fully functional playbook

**Professional automation for system configuration, security hardening, and monitoring across Ubuntu/Debian servers.**

A production-ready Ansible framework with **22 comprehensive roles** organized across **4 implementation layers**: Essentials, Applications & Services, Security, and Monitoring. Includes automated VM initialization, SSH hardening, user management, and complete observability stack.

---

## Table of Contents

- [Quick Start](#-quick-start)
- [Framework Architecture](#-framework-architecture)
- [Project Structure](#-project-structure)
- [Role Reference](#-role-reference)
- [Playbook Reference](#-playbook-reference)
- [Configuration](#-configuration--variables)
- [Docker Setup](#-docker-setup)
- [Semaphore Setup](#-semaphore-setup)
- [Security Stack](#-security-stack)
- [Monitoring Stack](#-monitoring-stack)
- [Troubleshooting](#-troubleshooting)
- [Command Reference](#-command-reference)

---

## 🚀 Quick Start

### Setup in 4 Steps (Fresh VM)

#### Step 1: Get Your SSH Public Key (1 minute)
\`\`\`bash
cat ~/.ssh/id_ed25519.pub
# Copy this entire output
\`\`\`

#### Step 2: Update Configuration (2 minutes)

**Edit:** \`group_vars/users.yml\`
\`\`\`yaml
ops_users:
  - name: John
    ssh_keys:
      - "ssh-ed25519 AAAA... John@workstation"  # ← PASTE YOUR KEY HERE
\`\`\`

**Edit:** \`inventory/sample_inventory.yml\`
\`\`\`yaml
common_ubuntu:
  hosts:
    common-01:
      ansible_host: 192.168.X.X  # ← YOUR VM IP HERE
\`\`\`

#### Step 3: Run Setup Playbook (2-3 minutes)
\`\`\`bash
ansible-playbook playbooks/setup.yml \\
  -i inventory/sample_inventory.yml \\
  -u John \\
  -k \\
  --ask-become-pass
\`\`\`

When prompted:
- SSH password: (John's password from VM installation)
- Become password: (usually same as SSH password)

#### Step 4: Verify & Deploy (5-10 minutes)
\`\`\`bash
# Verify setup worked
ansible all -i inventory/sample_inventory.yml -m ping

# Deploy full configuration
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml
\`\`\`

**Done!** You now have a fully configured production server! 🎉

### What Happens During Setup

\`\`\`
Fresh VM (John + password auth)
          ↓
    [setup.yml runs]
          ↓
Creates: ansible user (uid 1000)
Configures: SSH keys for John
Hardens: SSH (disables password auth)
Enables: Passwordless sudo for ansible
          ↓
Ready for Automation ✅
\`\`\`

### For Existing Infrastructure

\`\`\`bash
# Deploy all roles
ansible-playbook playbooks/site.yml

# Deploy to specific group
ansible-playbook playbooks/docker-hosts.yml
ansible-playbook playbooks/semaphore-hosts.yml
ansible-playbook playbooks/common-hosts.yml

# Deploy specific roles only
ansible-playbook playbooks/site.yml --tags=docker,prometheus,ssh

# Dry-run (check mode, no changes)
ansible-playbook playbooks/site.yml --check
\`\`\`

---

## 🏗️ Framework Architecture

### 4 Implementation Layers

\`\`\`
┌──────────────────────────────────────────────────────┐
│  ESSENTIALS (9 roles)                                │
│  APT  Packages  Users  SSH  Timezone  Hostname       │
│  Firewall  Mail  Updates  User Ops                   │
├──────────────────────────────────────────────────────┤
│  APPS & SERVICES (2 roles)                           │
│  Docker    Semaphore                                  │
├──────────────────────────────────────────────────────┤
│  SECURITY (4 roles)                                  │
│  AppArmor  OSSEC  Maldet  Lynis                      │
├──────────────────────────────────────────────────────┤
│  MONITORING (7 roles)                                │
│  Loki  Prometheus  Grafana Agent  Alertmanager       │
│  Log Rotation  Monit                                 │
└──────────────────────────────────────────────────────┘
\`\`\`

### Execution Flow

\`\`\`
START
  │
  ├─► setup.yml (FRESH VM ONLY)
  │    ├─► Create ansible user
  │    ├─► Configure SSH keys
  │    └─► Harden SSH
  │
  ├─► site.yml (FULL DEPLOYMENT)
  │    ├─► Essentials (9 roles)
  │    ├─► Apps & Services (2 roles)
  │    ├─► Security (4 roles)
  │    └─► Monitoring (7 roles)
  │
  END ✅
\`\`\`

### Host Groups

| Group | Purpose | Docker | Semaphore |
|-------|---------|--------|---------|
| \`common_ubuntu\` | Basic infrastructure | ❌ | ❌ |
| \`docker_hosts\` | Container platforms | ✅ | ❌ |
| \`semaphore_hosts\` | Automation servers | ❌ | ✅ |
| \`ubuntu_desktop\` | Workstations | ✅ | ❌ |

**Critical**: Docker and Semaphore never run on the same host.

---

## 📂 Project Structure

\`\`\`
Ansible-playbook/
│
├── 📝 playbooks/
│   ├── site.yml                 # Full deployment (all 22 roles)
│   ├── setup.yml                # Fresh VM initialization
│   ├── docker-hosts.yml         # Docker servers
│   ├── semaphore-hosts.yml      # Semaphore servers
│   ├── common-hosts.yml         # Basic servers
│   ├── desktop-hosts.yml        # Workstations
│   ├── essentials.yml           # Core roles only
│   ├── security-full.yml        # All security roles
│   ├── monitoring-full.yml      # All monitoring roles
│   ├── security.yml             # SSH + Firewall
│   ├── updates.yml              # APT + Updates
│   ├── system.yml               # Hostname + Timezone
│   ├── apps.yml                 # Docker + Semaphore
│   └── diagnostic.yml           # Validation
│
├── 🎭 roles/
│   ├── apt/                     # APT & repositories
│   ├── packages/                # Essential packages
│   ├── user_accounts/           # Users & groups
│   ├── users_ops/               # Operational users
│   ├── ssh/                     # SSH hardening
│   ├── timezone/                # Timezone & NTP
│   ├── hostname/                # Hostname config
│   ├── firewall/                # UFW rules
│   ├── mail/                    # Postfix service
│   ├── updates/                 # Auto updates
│   ├── docker/                  # Container platform
│   ├── semaphore/               # Ansible UI automation
│   ├── apparmor/                # MAC profiles
│   ├── integrity_monitoring/    # OSSEC
│   ├── malware_scanning/        # Maldet
│   ├── security_audits/         # Lynis
│   ├── log_rotation/            # Logrotate
│   ├── loki/                    # Log aggregation
│   ├── prometheus/              # Metrics storage
│   ├── grafana_agent/           # Data collection
│   ├── alertmanager/            # Alert routing
│   └── monit/                   # Service monitoring
│
├── 📂 inventory/
│   ├── sample_inventory.yml     # Host definitions
│   └── README.md                # Inventory guide
│
├── 📂 group_vars/
│   ├── all.yml                  # Global variables
│   ├── users.yml                # User definitions
│   └── vault.yml                # Encrypted secrets
│
├── 📂 docs/
│   ├── QUICK_REFERENCE_CARD.md  # Command reference
│   ├── WORKFLOW.md              # Workflow diagrams
│   ├── PRE_FLIGHT_CHECKLIST.md  # Verification items
│   └── README.md                # Documentation index
│
└── ansible.cfg                  # Ansible configuration
\`\`\`

---

## 🎭 Role Reference

### Essentials (9 Roles)

| Role | Tag | Purpose |
|------|-----|---------|
| **apt** | \`apt\` | APT repository and package cache management |
| **packages** | \`packages\` | Essential packages installation (curl, vim, htop, etc.) |
| **user_accounts** | \`users\` | User and group management |
| **users_ops** | \`users-ops\` | Operational users with SSH keys |
| **ssh** | \`ssh\` | SSH configuration and hardening |
| **timezone** | \`timezone\` | System timezone and NTP synchronization |
| **hostname** | \`hostname\` | Hostname and hosts file configuration |
| **firewall** | \`firewall\` | UFW firewall rules management |
| **mail** | \`mail\` | Postfix mail service setup |
| **updates** | \`updates\` | Unattended security updates |

### Apps & Services (2 Roles)

| Role | Tag | Purpose |
|------|-----|---------|
| **docker** | \`docker\` | Docker CE, CLI, Compose installation |
| **semaphore** | \`semaphore\` | Ansible UI automation platform (port 3000) |

### Security (4 Roles)

| Role | Tag | Purpose |
|------|-----|---------|
| **apparmor** | \`apparmor\` | Mandatory Access Control (MAC) profiles |
| **integrity_monitoring** | \`integrity-monitoring\` | OSSEC file integrity monitoring |
| **malware_scanning** | \`malware-scanning\` | Maldet daily malware detection |
| **security_audits** | \`security-audits\` | Lynis compliance auditing |

### Monitoring (7 Roles)

| Role | Tag | Purpose | Port |
|------|-----|---------|------|
| **log_rotation** | \`log-rotation\` | Logrotate configuration | - |
| **loki** | \`loki\` | Log aggregation and storage | 3100 |
| **prometheus** | \`prometheus\` | Metrics storage and querying | 9090 |
| **grafana_agent** | \`grafana-agent\` | Log/metrics collection and shipping | - |
| **alertmanager** | \`alertmanager\` | Alert routing and notifications | 9093 |
| **monit** | \`monit\` | Service monitoring and auto-restart | 2812 |

---

## 📝 Playbook Reference

### Primary Playbooks

\`\`\`bash
# Complete deployment (all 22 roles)
ansible-playbook playbooks/site.yml

# Fresh VM initialization
ansible-playbook playbooks/setup.yml -u John -k --ask-become-pass
\`\`\`

### Group-Specific Playbooks

\`\`\`bash
# Docker servers
ansible-playbook playbooks/docker-hosts.yml

# Semaphore servers
ansible-playbook playbooks/semaphore-hosts.yml

# Basic servers
ansible-playbook playbooks/common-hosts.yml

# Workstations
ansible-playbook playbooks/desktop-hosts.yml
\`\`\`

### Focused Playbooks

\`\`\`bash
# Core infrastructure only
ansible-playbook playbooks/essentials.yml

# All security roles
ansible-playbook playbooks/security-full.yml

# All monitoring roles
ansible-playbook playbooks/monitoring-full.yml

# SSH + Firewall only
ansible-playbook playbooks/security.yml

# System updates
ansible-playbook playbooks/updates.yml

# Docker + Semaphore
ansible-playbook playbooks/apps.yml
\`\`\`

### Tag-Based Deployment

\`\`\`bash
# Single role
ansible-playbook playbooks/site.yml --tags=docker

# Multiple roles
ansible-playbook playbooks/site.yml --tags=ssh,firewall,prometheus

# Skip roles
ansible-playbook playbooks/site.yml --skip-tags=mail,semaphore

# All security
ansible-playbook playbooks/site.yml --tags=security

# All monitoring
ansible-playbook playbooks/site.yml --tags=monitoring
\`\`\`

---

## ⚙️ Configuration & Variables

### Variables Hierarchy

\`\`\`
ansible.cfg (global config)
    ↓
group_vars/
    ├── all.yml              (ALL HOSTS - primary)
    └── users.yml            (User definitions)
    ↓
host_vars/
    └── hostname.yml         (Individual host overrides)
\`\`\`

### Key Configuration Files

#### group_vars/all.yml
\`\`\`yaml
# System
system_timezone: UTC
system_hostname: server1

# SSH
ssh_port: 22
ssh_permit_root_login: 'no'
ssh_password_auth: 'no'

# Firewall
firewall_rules: []

# Docker
docker_users: [ansible]
docker_compose_install: true

# Semaphore
semaphore_port: 3000

# Monitoring
prometheus_retention_time: 30d
loki_retention_days: 30
\`\`\`

#### group_vars/users.yml
\`\`\`yaml
ops_users:
  - name: John
    ssh_keys:
      - "ssh-ed25519 AAAA... John@workstation"
    groups: [sudo, docker]
\`\`\`

#### inventory/sample_inventory.yml
\`\`\`yaml
all:
  children:
    common_ubuntu:
      hosts:
        common-01:
          ansible_host: 192.168.1.100
    docker_hosts:
      hosts:
        docker-01:
          ansible_host: 192.168.1.110
    semaphore_hosts:
      hosts:
        semaphore-01:
          ansible_host: 192.168.1.120
    ubuntu_desktop:
      hosts:
        desktop-01:
          ansible_host: 192.168.1.130
\`\`\`

---

## 🐳 Docker Setup

### Features
- Official Docker repository setup
- Docker CE, Docker CLI, and containerd installation
- Docker Compose (latest version)
- Service enablement and startup
- Docker group and user management
- Daemon configuration (logging, live restore)

### Configuration

\`\`\`yaml
# group_vars/all.yml
docker_users:
  - ansible
  - ubuntu

docker_log_driver: json-file
docker_log_max_size: 10m
docker_log_max_file: 3
docker_live_restore: true
docker_userland_proxy: false
docker_compose_install: true
\`\`\`

### Deployment

\`\`\`bash
# Install Docker
ansible-playbook playbooks/site.yml --tags=docker

# Or use apps playbook
ansible-playbook playbooks/apps.yml --tags=docker
\`\`\`

### Verification

\`\`\`bash
# On remote host
docker --version
docker-compose --version
docker run hello-world
\`\`\`



## 🔐 Security Stack

### Overview

| Role | Purpose | Schedule |
|------|---------|----------|
| **AppArmor** | Mandatory Access Control | On-boot |
| **OSSEC** | File integrity monitoring | Hourly + Real-time |
| **Maldet** | Malware scanning | Daily at 2 AM |
| **Lynis** | Security audits | Daily at 5 AM |

### AppArmor

**Purpose**: Process confinement via kernel MAC

\`\`\`yaml
# Variables
apparmor_enforce_profiles: []
apparmor_complain_profiles: []
apparmor_custom_profiles: []
\`\`\`

\`\`\`bash
# Deploy
ansible-playbook playbooks/site.yml --tags=apparmor

# Verify
sudo aa-status
\`\`\`

### Integrity Monitoring (OSSEC)

**Purpose**: File integrity monitoring with real-time alerts

\`\`\`yaml
# Variables
ossec_version: 3.7.0
ossec_email_notifications: false
ossec_admin_email: "root"
ossec_monitored_paths:
  - /etc
  - /bin
  - /usr/bin
  - /root
ossec_syscheck_interval: 3600
ossec_syscheck_realtime: "yes"
\`\`\`

\`\`\`bash
# Deploy with email alerts
ansible-playbook playbooks/security-full.yml --tags=integrity-monitoring \\
  -e ossec_email_notifications=true \\
  -e ossec_admin_email="admin@example.com"

# Verify
sudo /var/ossec/bin/agent_control -i
tail -f /var/ossec/logs/alerts/alerts.log
\`\`\`

### Malware Scanning (Maldet)

**Purpose**: Daily malware detection and quarantine

\`\`\`yaml
# Variables
maldet_email_notifications: false
maldet_admin_email: "root"
maldet_scan_hour: 2
maldet_scan_paths:
  - /home
  - /var/www
  - /root
maldet_quarantine_suspicious: true
\`\`\`

\`\`\`bash
# Deploy
ansible-playbook playbooks/security-full.yml --tags=malware-scanning

# Manual scan
sudo /usr/local/sbin/maldet -a /home /var/www

# View reports
ls -l /var/log/maldet-reports/
\`\`\`

### Security Audits (Lynis)

**Purpose**: Daily security compliance audits

\`\`\`yaml
# Variables
lynis_audit_hour: 5
lynis_email_notifications: false
lynis_admin_email: "root"
\`\`\`

\`\`\`bash
# Deploy
ansible-playbook playbooks/security-full.yml --tags=security-audits

# Manual audit
sudo lynis audit system

# View report
cat /var/log/lynis-report.dat
\`\`\`

### Deploy All Security

\`\`\`bash
ansible-playbook playbooks/security-full.yml
\`\`\`

---

## 📊 Monitoring Stack

### Architecture

\`\`\`
System Logs → Grafana Agent → Loki (3100)
System Metrics → Grafana Agent → Prometheus (9090)
Alert Rules → Alertmanager (9093) → Notifications
Services → Monit (2812) → Auto-restart
\`\`\`

### Log Rotation

**Purpose**: Prevent log files from consuming disk space

\`\`\`yaml
# Variables
log_rotation_retention_days: 30
log_rotation_max_age_days: 60
log_rotation_max_size: 100M
log_rotation_cron_hour: 3
log_rotation_compress: true
\`\`\`

\`\`\`bash
# Deploy
ansible-playbook playbooks/site.yml --tags=log-rotation

# Verify
ls -lah /var/log/*.gz
logrotate -d /etc/logrotate.conf
\`\`\`

### Loki

**Purpose**: Centralized log aggregation

\`\`\`yaml
# Variables
loki_version: 2.9.0
loki_retention_days: 30
loki_http_port: 3100
\`\`\`

\`\`\`bash
# Deploy
ansible-playbook playbooks/site.yml --tags=loki

# Verify
curl http://localhost:3100/loki/api/v1/status/buildinfo
curl http://localhost:3100/api/prom/ready
\`\`\`

### Prometheus

**Purpose**: Metrics storage and querying

\`\`\`yaml
# Variables
prometheus_version: 2.48.0
prometheus_port: 9090
prometheus_scrape_interval: 15s
prometheus_retention_time: 30d
\`\`\`

\`\`\`bash
# Deploy
ansible-playbook playbooks/site.yml --tags=prometheus

# Verify
curl http://localhost:9090/-/healthy
curl http://localhost:9090/api/v1/status/config
\`\`\`

**Web UI**: \`http://localhost:9090\`

### Grafana Agent

**Purpose**: Collect and ship logs/metrics

\`\`\`yaml
# Variables
loki_push_url: "http://localhost:3100/loki/api/v1/push"
prometheus_push_url: "http://localhost:9090/api/v1/write"
grafana_agent_scrape_interval: 15s
grafana_agent_collect_node_metrics: true
\`\`\`

\`\`\`bash
# Deploy
ansible-playbook playbooks/site.yml --tags=grafana-agent

# Verify
systemctl status grafana-agent
\`\`\`

### Alertmanager

**Purpose**: Alert routing and notifications

\`\`\`yaml
# Variables
alertmanager_port: 9093
alertmanager_email_to: "admin@example.com"
alertmanager_slack_webhook: "{{ vault_slack_webhook }}"
\`\`\`

\`\`\`bash
# Deploy
ansible-playbook playbooks/site.yml --tags=alertmanager

# Verify
curl http://localhost:9093/-/healthy
\`\`\`

**Web UI**: \`http://localhost:9093\`

### Monit

**Purpose**: Service monitoring and auto-restart

\`\`\`yaml
# Variables
monit_port: 2812
monit_check_interval: 60
monit_alert_email: "admin@example.com"
\`\`\`

\`\`\`bash
# Deploy
ansible-playbook playbooks/site.yml --tags=monit

# Verify
sudo monit status
\`\`\`

**Web UI**: \`http://localhost:2812\`

### Deploy All Monitoring

\`\`\`bash
ansible-playbook playbooks/monitoring-full.yml
\`\`\`

---

## 🔧 Troubleshooting

### Connection Issues

**Problem**: SSH connection refused
\`\`\`bash
# Verify VM is running
ping 192.168.X.X

# Check SSH service on VM
sudo systemctl status ssh

# Check firewall
sudo ufw allow 22/tcp
\`\`\`

**Problem**: Permission denied (publickey)
\`\`\`bash
# Use password auth for initial setup
ansible-playbook playbooks/setup.yml -u John -k --ask-become-pass
\`\`\`

### Setup Playbook Failed

**Problem**: Playbook stopped mid-execution

**Solution**:
1. Check which step failed in output
2. Fix the issue (e.g., add SSH key to users.yml)
3. Re-run - playbooks are idempotent (safe to re-run)

### Can't Connect After Setup

**Problem**: SSH fails after setup.yml completed

**Cause**: SSH keys weren't properly configured

**Solution**:
1. Verify your public key is in \`group_vars/users.yml\`
2. Verify it's the correct key
3. Re-run setup.yml if needed

### Service Issues

**Problem**: Service not starting

\`\`\`bash
# Check service status
systemctl status <service-name>

# Check logs
journalctl -u <service-name> -f

# Check port
ss -tlnp | grep <port>
\`\`\`

---

## 📋 Command Reference

### Syntax Check
\`\`\`bash
ansible-playbook playbooks/site.yml --syntax-check
\`\`\`

### Dry Run
\`\`\`bash
ansible-playbook playbooks/site.yml --check --diff
\`\`\`

### Run with Tags
\`\`\`bash
ansible-playbook playbooks/site.yml --tags "security,firewall"
\`\`\`

### Limit to Hosts
\`\`\`bash
ansible-playbook playbooks/site.yml --limit "webservers"
\`\`\`

### Encrypt Secrets
\`\`\`bash
ansible-vault encrypt group_vars/vault.yml
ansible-vault edit group_vars/vault.yml
\`\`\`

### Lint Playbooks
\`\`\`bash
ansible-lint playbooks/ roles/
\`\`\`

### Test Connectivity
\`\`\`bash
ansible all -i inventory/sample_inventory.yml -m ping
\`\`\`

### Get Facts
\`\`\`bash
ansible all -m setup | head -100
\`\`\`

### Ad-hoc Commands
\`\`\`bash
# Run command on all hosts
ansible all -m command -a "uptime"

# Check disk space
ansible all -m command -a "df -h"

# Restart service
ansible all -m service -a "name=nginx state=restarted"
\`\`\`

---

## 📊 Project Statistics

| Metric | Value |
|--------|-------|
| Total Roles | 22 |
| Essential Roles | 9 |
| Security Roles | 4 |
| Monitoring Roles | 7 |
| Apps & Services | 2 |
| Playbooks | 14 |
| Host Groups | 4 |
| Setup Time | 2-3 minutes |
| Full Deploy Time | 5-10 minutes |

---

## ✅ Getting Started Checklist

- [ ] Generate SSH key pair (\`ssh-keygen -t ed25519\`)
- [ ] Update \`group_vars/users.yml\` with your SSH key
- [ ] Edit \`inventory/sample_inventory.yml\` with VM IPs
- [ ] Update \`group_vars/all.yml\` with your settings
- [ ] Run \`setup.yml\` on fresh VM
- [ ] Verify with \`ansible all -m ping\`
- [ ] Run \`site.yml\` for full deployment
- [ ] Verify services (Prometheus :9090, Loki :3100, Alertmanager :9093)

---

## 🔐 Security Best Practices

1. **SSH Keys**: Use ed25519, restrict permissions (600), store securely
2. **Vault Secrets**: Encrypt \`group_vars/vault.yml\`, use strong password
3. **Access Control**: Audit sudo logs, restrict SSH to needed users
4. **Monitoring**: Review logs daily, set up alerting, track security events

---

## 📜 License

**DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE** - Version 2, December 2004

This project is released under the WTFPL. See [LICENSE](LICENSE) for details.
