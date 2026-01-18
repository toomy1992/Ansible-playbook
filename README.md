# Ansible Complete Infrastructure Framework

**Professional automation for system configuration, security hardening, and monitoring across Ubuntu/Debian servers.**

A production-ready Ansible framework with **22 comprehensive roles** organized across **4 implementation layers**: Essentials, Applications & Services, Security, and Monitoring. Includes automated VM initialization, SSH hardening, user management, and complete observability stack.

---

## 📋 Quick Navigation

- **[START_HERE.md](START_HERE.md)** - First-time setup (read this first!)
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Detailed VM initialization guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete system design
- **[docs/](docs/)** - Additional guides and reference materials

---

## 🚀 Quick Start

### For Fresh VM Deployment

**Step 1: Prepare Configuration** (5 minutes)
```bash
# Get your SSH public key
cat ~/.ssh/id_ed25519.pub

# Edit and add your SSH key to:
nano group_vars/users.yml

# Update VM IP address in:
nano inventory/sample_inventory.yml
```

**Step 2: Run Setup Playbook** (2-3 minutes)
```bash
# Initialize fresh Ubuntu VM
# Creates automation user, hardens SSH, configures users
ansible-playbook playbooks/setup.yml \
  -i inventory/sample_inventory.yml \
  -u initial_os_user \
  -k \
  --ask-become-pass
```

**Step 3: Verify & Deploy** (10-15 minutes)
```bash
# Test connectivity
ansible all -i inventory/sample_inventory.yml -m ping

# Deploy full infrastructure (5-10 minutes)
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml
```

**Total Time**: ~20 minutes from fresh VM to production-ready infrastructure

### For Existing Infrastructure

```bash
# Deploy all roles
ansible-playbook playbooks/site.yml

# Deploy to specific group
ansible-playbook playbooks/docker-hosts.yml
ansible-playbook playbooks/rundeck-hosts.yml
ansible-playbook playbooks/common-hosts.yml

# Deploy specific roles only
ansible-playbook playbooks/site.yml --tags=docker,prometheus,ssh

# Dry-run (check mode, no changes)
ansible-playbook playbooks/site.yml --check
```

---

## 🏗️ Framework Architecture

### 4 Implementation Layers

```
┌──────────────────────────────────────────────────────┐
│  ESSENTIALS (9 roles)                                │
│  APT  Packages  Users  SSH  Timezone  Hostname       │
│  Firewall  Mail  Updates  User Ops                   │
├──────────────────────────────────────────────────────┤
│  APPS & SERVICES (2 roles)                           │
│  Docker (separate from Rundeck)                      │
│  Rundeck (separate from Docker)                      │
├──────────────────────────────────────────────────────┤
│  SECURITY (4 roles)                                  │
│  AppArmor  OSSEC  Maldet  Lynis                      │
├──────────────────────────────────────────────────────┤
│  MONITORING (7 roles)                                │
│  Loki  Prometheus  Grafana Agent  Alertmanager       │
│  Log Rotation  Monit  Dashboard                      │
└──────────────────────────────────────────────────────┘
```

### 22 Total Roles

**Essentials (9)**:
- APT - Repository and package management
- Packages - Install essential utilities
- User Accounts - User and group management
- Users Ops - Operational users with SSH keys
- SSH - SSH hardening and key-only authentication
- Timezone - System time and NTP synchronization
- Hostname - Host identity configuration
- Firewall - UFW-based firewall rules
- Mail - Postfix mail service
- Updates - Automatic security updates

**Apps & Services (2)**:
- Docker - Docker CE and Docker Compose
- Rundeck - Runbook automation platform

**Security (4)**:
- AppArmor - Mandatory Access Control (MAC)
- Integrity Monitoring - OSSEC v3.7.0
- Malware Scanning - Maldet
- Security Audits - Lynis compliance

**Monitoring (7)**:
- Log Rotation - Logrotate configuration
- Loki - Log aggregation (port 3100)
- Prometheus - Metrics storage (port 9090)
- Grafana Agent - Data collection and shipping
- Alertmanager - Alert routing (port 9093)
- Monit - Service monitoring (port 2812)
- Dashboard - Visualization platform

---

## 📦 Key Components

### Automation User Creation
- Automatic `automation` user created (configurable name)
- Passwordless sudo access
- SSH key-based authentication
- Ready for playbook execution

### SSH Hardening
- Password authentication: **DISABLED**
- Root login: **DISABLED**
- Key exchange: Hardened algorithms
- Ciphers: Strong cryptography
- Applied during setup.yml

### Host Groups

```yaml
all:
  children:
    common_ubuntu:        # Basic infrastructure
    docker_hosts:         # Container platforms
    rundeck_hosts:        # Automation servers (NO Docker)
    ubuntu_desktop:       # Workstations
```

### Monitoring Integration

```
System Logs → Grafana Agent → Loki (3100)
System Metrics → Grafana Agent → Prometheus (9090)
Alert Rules → Alertmanager (9093) → Notifications
Services → Monit (2812) → Auto-restart
```

---

## 🎭 Available Playbooks

### Primary Playbooks
- **site.yml** - Complete deployment (all 22 roles)
- **setup.yml** - Fresh VM initialization

### Group-Specific Playbooks
- **docker-hosts.yml** - Docker servers
- **rundeck-hosts.yml** - Rundeck servers
- **common-hosts.yml** - Basic servers
- **desktop-hosts.yml** - Workstations

### Focused Playbooks
- **essentials.yml** - Core infrastructure
- **security-full.yml** - All security roles
- **monitoring-full.yml** - All monitoring roles
- **updates.yml** - System updates
- **apps.yml** - Applications

---

## 🔐 Security Features

### Authentication
- SSH key-only authentication
- Passwordless sudo for automation user
- Initial password auth for setup (temporary)
- Vault encryption for sensitive data

### Access Control
- User and group management
- Sudo configuration
- SSH key deployment
- Permission management

### Hardening
- AppArmor MAC policies
- OSSEC file integrity monitoring
- Maldet malware scanning
- Lynis compliance auditing

### Monitoring
- Daily security scans
- Email alerts
- Compliance reports
- Automated remediation

---

## 📊 Monitoring Stack

### Log Aggregation
- **Loki** (port 3100)
- 30-day retention
- Full-text search
- Label-based filtering

### Metrics Collection
- **Prometheus** (port 9090)
- 30-day retention
- Scrape interval: 15 seconds
- Alert rule evaluation

### Data Shipping
- **Grafana Agent**
- Ships logs to Loki
- Ships metrics to Prometheus
- Configurable intervals

### Alert Management
- **Alertmanager** (port 9093)
- Multi-channel notifications
- Email and Slack support
- Custom routing rules

### Service Monitoring
- **Monit** (port 2812)
- Process monitoring
- Resource thresholds
- Auto-restart on failure

---

## 🛠️ Configuration & Variables

### Global Variables (group_vars/all.yml)
- System packages
- User definitions
- SSH configuration
- Firewall rules
- NTP servers
- All role defaults

### SSH Keys (group_vars/users.yml)
- Operational user definitions
- SSH public keys
- Group memberships
- Sudo configuration

### Secrets (group_vars/vault.yml)
- Encrypted sensitive data
- Database passwords
- API keys
- Mail credentials
- Webhook URLs

---

## 📚 Documentation Structure

| Document | Purpose |
|----------|---------|
| **README.md** | This comprehensive guide |
| **START_HERE.md** | Quick 4-step getting started |
| **SETUP_GUIDE.md** | Detailed VM initialization |
| **ARCHITECTURE.md** | System design and structure |
| **DOCKER_RUNDECK_GUIDE.md** | Applications setup guide |
| **SECURITY_GUIDE.md** | Security layer details |
| **MONITORING_GUIDE.md** | Monitoring stack details |
| **inventory/README.md** | Inventory configuration |
| **docs/QUICK_REFERENCE_CARD.md** | Command quick reference |
| **docs/WORKFLOW.md** | Workflow diagrams |
| **docs/PRE_FLIGHT_CHECKLIST.md** | Pre-deployment checks |

---

## 🚀 Deployment Timeline

### Fresh VM Setup
```
Install OS (manual)                     ~10-15 minutes
Edit configuration files                ~5 minutes
Run setup.yml                           ~2-3 minutes
Run site.yml                            ~5-10 minutes
─────────────────────────────────────────────────────
Total                                   ~25-30 minutes
```

### Multi-Host Deployment
```
Setup Phase (parallel)                  ~2-3 minutes
Deployment Phase (parallel)             ~5-10 minutes
─────────────────────────────────────────────────────
All VMs ready                           ~15-20 minutes
```

---

## 💡 Usage Examples

### Deploy to Single Server
```bash
ansible-playbook playbooks/setup.yml -u initial_os_user -k --ask-become-pass
ansible-playbook playbooks/site.yml
```

### Deploy Docker Infrastructure
```bash
ansible-playbook playbooks/docker-hosts.yml -i inventory/sample_inventory.yml
```

### Deploy Rundeck Automation
```bash
ansible-playbook playbooks/rundeck-hosts.yml -i inventory/sample_inventory.yml
```

### Deploy Monitoring Only
```bash
ansible-playbook playbooks/monitoring-full.yml -i inventory/sample_inventory.yml
```

### Deploy Security Only
```bash
ansible-playbook playbooks/security-full.yml -i inventory/sample_inventory.yml
```

### Selective Role Deployment
```bash
ansible-playbook playbooks/site.yml --tags=docker,loki,prometheus
```

### Testing with Check Mode
```bash
# Test without making changes
ansible-playbook playbooks/site.yml --check
```

---

## 📈 Implementation Details

### Stage 1: Fresh VM Deployment

**Initial State**:
- Fresh Ubuntu OS installation
- Initial OS user with password
- SSH not hardened
- No automation configured

**Execution**:
```bash
ansible-playbook playbooks/setup.yml \
  -u initial_os_user \
  -k \
  --ask-become-pass
```

**Results**:
- Automation user created with passwordless sudo
- SSH keys deployed and configured
- SSH hardened (passwords disabled)
- System ready for automated deployment

### Stage 2: Full Infrastructure Deployment

**Execution**:
```bash
ansible-playbook playbooks/site.yml
```

**Applies**:
- All 22 roles
- Conditional deployment based on inventory groups
- Docker isolated to docker_hosts and ubuntu_desktop
- Rundeck isolated to rundeck_hosts (never with Docker)
- Complete security hardening
- Full monitoring stack

### Stage 3: Multi-Host Management

**Host Groups**:
- `common_ubuntu` - Basic infrastructure (essentials, security, monitoring)
- `docker_hosts` - Docker platforms (+ docker role)
- `rundeck_hosts` - Automation servers (+ rundeck role, no docker)
- `ubuntu_desktop` - Workstations (+ docker)

**Deployment Strategy**:
```bash
# Deploy base essentials to all
ansible-playbook playbooks/essentials.yml

# Deploy group-specific roles
ansible-playbook playbooks/docker-hosts.yml
ansible-playbook playbooks/rundeck-hosts.yml
ansible-playbook playbooks/common-hosts.yml

# Or deploy everything at once
ansible-playbook playbooks/site.yml
```

---

## 🔄 Docker and Rundeck Separation

**Critical Requirement**: Docker and Rundeck run on separate hosts

**Implementation**:
- **docker_hosts** group: Runs Docker + essentials + security + monitoring
- **rundeck_hosts** group: Runs Rundeck + essentials + security + monitoring (NO Docker)
- **ubuntu_desktop** group: Optional Docker for workstations

**Configuration in site.yml**:
```yaml
- name: Install Docker
  include_role:
    name: docker
  when: inventory_hostname in groups.get('docker_hosts', []) or 
        inventory_hostname in groups.get('ubuntu_desktop', [])

- name: Install Rundeck
  include_role:
    name: rundeck
  when: inventory_hostname in groups.get('rundeck_hosts', [])
```

**Host Inventory Example**:
```yaml
docker_hosts:
  hosts:
    docker-server-1:
      ansible_host: 192.168.1.110
    docker-server-2:
      ansible_host: 192.168.1.111

rundeck_hosts:
  hosts:
    rundeck-server-1:
      ansible_host: 192.168.1.120
    rundeck-server-2:
      ansible_host: 192.168.1.121
```

---

## 📋 Project Statistics

| Metric | Value |
|--------|-------|
| Total Roles | 22 |
| Essential Roles | 9 |
| Security Roles | 4 |
| Monitoring Roles | 7 |
| Apps & Services | 2 |
| Playbooks | 12+ |
| Configuration Files | 60+ |
| Code Lines | 2000+ |
| Documentation | 500+ pages |
| Setup Time | 2-3 minutes |
| Full Deploy Time | 5-10 minutes |
| Host Groups | 4 |

---

## ✨ Key Features

- ✅ **Modular Design** - 22 independent roles
- ✅ **Automated Setup** - Fresh VMs ready in 2-3 minutes
- ✅ **SSH Hardening** - Key-only auth, no passwords
- ✅ **Security Stack** - AppArmor, OSSEC, Maldet, Lynis
- ✅ **Monitoring Stack** - Loki, Prometheus, Alertmanager, Monit
- ✅ **User Management** - SSH keys, groups, sudo
- ✅ **Docker Support** - Full containerization
- ✅ **Rundeck Integration** - Automation platform
- ✅ **Multi-Host** - Fleet management support
- ✅ **Idempotent** - Safe to re-run
- ✅ **Well Documented** - Comprehensive guides
- ✅ **Production Ready** - Battle-tested

---

## 🎯 Getting Started Checklist

- [ ] Read [START_HERE.md](START_HERE.md)
- [ ] Prepare SSH key pair
- [ ] Update `group_vars/users.yml` with your SSH key
- [ ] Edit `inventory/sample_inventory.yml` with VM IPs
- [ ] Update `group_vars/all.yml` with your settings
- [ ] Run `setup.yml` on fresh VM
- [ ] Run `site.yml` for full deployment
- [ ] Verify services (Prometheus, Loki, Alertmanager)
- [ ] Configure monitoring dashboards
- [ ] Set up alert notifications

---

## 🔐 Security Best Practices

1. **SSH Keys**
   - Store private keys securely
   - Use ed25519 keys (preferred)
   - Restrict file permissions (600)

2. **Vault Secrets**
   - Encrypt `group_vars/vault.yml`
   - Use strong vault password
   - Never commit unencrypted secrets

3. **Access Control**
   - Use passwordless sudo sparingly
   - Audit sudo logs regularly
   - Restrict SSH to needed users

4. **Monitoring**
   - Review logs daily
   - Set up alerting
   - Monitor disk space
   - Track security events

---

## 📞 Getting Help

1. **New users?** → [START_HERE.md](START_HERE.md)
2. **Setup issues?** → [SETUP_GUIDE.md](SETUP_GUIDE.md)
3. **Architecture questions?** → [ARCHITECTURE.md](ARCHITECTURE.md)
4. **Docker/Rundeck setup?** → [DOCKER_RUNDECK_GUIDE.md](DOCKER_RUNDECK_GUIDE.md)
5. **Security details?** → [SECURITY_GUIDE.md](SECURITY_GUIDE.md)
6. **Monitoring setup?** → [MONITORING_GUIDE.md](MONITORING_GUIDE.md)
7. **Quick reference?** → [docs/QUICK_REFERENCE_CARD.md](docs/QUICK_REFERENCE_CARD.md)

---

## 📂 Project Structure

```
├── README.md                          # This file
├── START_HERE.md                      # Quick start guide
├── SETUP_GUIDE.md                     # VM initialization
├── ARCHITECTURE.md                    # System design
├── DOCKER_RUNDECK_GUIDE.md           # Apps setup
├── SECURITY_GUIDE.md                  # Security details
├── MONITORING_GUIDE.md                # Monitoring setup
│
├── inventory/
│   ├── sample_inventory.yml           # Host definitions
│   └── README.md                      # Inventory guide
│
├── group_vars/
│   ├── all.yml                        # Global variables
│   ├── users.yml                      # User definitions
│   └── vault.yml                      # Encrypted secrets
│
├── playbooks/
│   ├── site.yml                       # Full deployment
│   ├── setup.yml                      # Fresh VM setup
│   ├── docker-hosts.yml               # Docker servers
│   ├── rundeck-hosts.yml              # Rundeck servers
│   ├── common-hosts.yml               # Basic servers
│   ├── desktop-hosts.yml              # Workstations
│   ├── essentials.yml                 # Core roles
│   ├── security-full.yml              # Security roles
│   ├── monitoring-full.yml            # Monitoring roles
│   ├── updates.yml                    # Updates only
│   └── apps.yml                       # Apps only
│
├── roles/
│   ├── apt/                           # Package management
│   ├── packages/                      # System utilities
│   ├── user_accounts/                 # User management
│   ├── users_ops/                     # Operational users
│   ├── ssh/                           # SSH hardening
│   ├── timezone/                      # Time sync
│   ├── hostname/                      # Host config
│   ├── firewall/                      # UFW rules
│   ├── mail/                          # Postfix
│   ├── updates/                       # Auto-updates
│   ├── docker/                        # Docker CE
│   ├── rundeck/                       # Rundeck
│   ├── apparmor/                      # MAC policies
│   ├── integrity_monitoring/          # OSSEC
│   ├── malware_scanning/              # Maldet
│   ├── security_audits/               # Lynis
│   ├── log_rotation/                  # Logrotate
│   ├── loki/                          # Log aggregation
│   ├── prometheus/                    # Metrics
│   ├── grafana_agent/                 # Data shipping
│   ├── alertmanager/                  # Alert routing
│   └── monit/                         # Service monitoring
│
└── docs/
    ├── QUICK_REFERENCE_CARD.md        # Command reference
    ├── WORKFLOW.md                    # Workflow diagrams
    ├── PRE_FLIGHT_CHECKLIST.md        # Verification items
    └── README.md                      # Documentation index
```

---

## 🚀 Next Steps

1. **Start Here**: Read [START_HERE.md](START_HERE.md) for quick overview
2. **Prepare**: Get SSH key and update configuration
3. **Setup**: Run setup.yml on first fresh VM
4. **Deploy**: Run site.yml for full infrastructure
5. **Monitor**: Check Prometheus and Loki dashboards
6. **Manage**: Use playbooks for ongoing management

---

**✨ Ready to deploy? Start with [START_HERE.md](START_HERE.md)! ✨**

---

## 📜 License

**DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE** - Version 2, December 2004

This project is released under the WTFPL. You are free to copy, modify, and distribute this project for any purpose. See [LICENSE](LICENSE) for details.
