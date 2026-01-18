# Ansible Complete Framework - Project Index

## 🎯 Quick Navigation

### 📖 Documentation
- **[README.md](README.md)** - Start here! Quick reference and overview
- **[MONITORING_GUIDE.md](MONITORING_GUIDE.md)** ⭐ Complete monitoring implementation
- **[SECURITY_GUIDE.md](SECURITY_GUIDE.md)** - Complete security implementation
- **[README_FULL.md](README_FULL.md)** - Complete detailed documentation
- **[PROJECT_INDEX.md](PROJECT_INDEX.md)** - This file - Navigation guide
- **[QUICK_REFERENCE.sh](QUICK_REFERENCE.sh)** - Bash quick reference commands

### 🎭 Roles (22 Total)

**Essentials (9 Roles):**
1. **[roles/apt](roles/apt)** - APT repository and package cache management
2. **[roles/packages](roles/packages)** - Essential packages installation
3. **[roles/user_accounts](roles/user_accounts)** - User and group management
4. **[roles/ssh](roles/ssh)** - SSH configuration and hardening
5. **[roles/timezone](roles/timezone)** - System timezone and NTP synchronization
6. **[roles/hostname](roles/hostname)** - Hostname and hosts file configuration
7. **[roles/firewall](roles/firewall)** - UFW firewall rules management
8. **[roles/mail](roles/mail)** - Postfix mail service setup
9. **[roles/updates](roles/updates)** - Unattended security updates

**Apps & Services (2 Roles):**
10. **[roles/docker](roles/docker)** - Docker installation and configuration
11. **[roles/rundeck](roles/rundeck)** - Rundeck runbook automation (Debian/Ubuntu)

**Security (4 Roles):**
12. **[roles/apparmor](roles/apparmor)** - Mandatory Access Control (MAC) profiles
13. **[roles/integrity_monitoring](roles/integrity_monitoring)** - OSSEC file integrity monitoring
14. **[roles/malware_scanning](roles/malware_scanning)** - Maldet daily malware detection
15. **[roles/security_audits](roles/security_audits)** - Lynis compliance auditing

**Monitoring (7 Roles):** ⭐ NEW
16. **[roles/log_rotation](roles/log_rotation)** - Automatic log management with logrotate
17. **[roles/loki](roles/loki)** - Log aggregation and storage service
18. **[roles/prometheus](roles/prometheus)** - Metrics storage and querying
19. **[roles/grafana_agent](roles/grafana_agent)** - Log shipping and metrics collection
20. **[roles/alertmanager](roles/alertmanager)** - Alert routing and notifications
21. **[roles/monit](roles/monit)** - Service monitoring and auto-restart

### 📝 Playbooks (8)
- **[playbooks/site.yml](playbooks/site.yml)** - Complete system configuration (all 22 roles)
- **[playbooks/monitoring-full.yml](playbooks/monitoring-full.yml)** - All 7 monitoring roles
- **[playbooks/security-full.yml](playbooks/security-full.yml)** - All 4 security roles
- **[playbooks/security.yml](playbooks/security.yml)** - SSH and firewall hardening
- **[playbooks/updates.yml](playbooks/updates.yml)** - APT, packages, and updates
- **[playbooks/system.yml](playbooks/system.yml)** - Hostname and timezone
- **[playbooks/apps.yml](playbooks/apps.yml)** - Docker and Rundeck installation
- **[playbooks/diagnostic.yml](playbooks/diagnostic.yml)** - System validation

### 📂 Configuration
- **[inventory/hosts](inventory/hosts)** - Static inventory template
- **[group_vars/](group_vars/)** - Group-level variables
- **[host_vars/](host_vars/)** - Host-specific variables
- **[ansible.cfg](ansible.cfg)** - Ansible configuration file

### 🛠️ Extensions
- **[templates/](templates/)** - Jinja2 templates directory
- **[library/](library/)** - Custom modules directory
- **[filter_plugins/](filter_plugins/)** - Custom filters directory

---

## 🚀 Quick Start (30 seconds)

```bash
# 1. Edit your hosts
vim inventory/hosts

# 2. Preview changes
ansible-playbook playbooks/site.yml --check

# 3. Deploy
ansible-playbook playbooks/site.yml
```

---

## 📋 Role Execution Tags

Run specific roles:
```bash
ansible-playbook playbooks/site.yml --tags=ssh,firewall
```

Available tags:
- `apt` - APT repository management
- `packages` - Package installation
- `users` - User account management
- `ssh` - SSH configuration
- `timezone` - Timezone and NTP
- `hostname` - Hostname configuration
- `firewall` - UFW firewall
- `mail` - Postfix mail service
- `updates` - Automatic updates
- `docker` - Docker installation
- `rundeck` - Rundeck automation
- `apparmor` - AppArmor MAC profiles
- `integrity-monitoring` - OSSEC monitoring
- `malware-scanning` - Maldet scanning
- `security-audits` - Lynis audits
- `security` - All security roles
- `log-rotation` - Log rotation with logrotate
- `loki` - Loki log aggregation
- `prometheus` - Prometheus metrics
- `grafana-agent` - Grafana Agent (logs + metrics)
- `alertmanager` - Alert routing
- `monit` - Service monitoring
- `monitoring` - All monitoring roles

---

## ⚙️ Common Configuration

Edit `group_vars/all.yml`:

```yaml
# System timezone
system_timezone: UTC

# SSH hardening
ssh_permit_root_login: 'no'
ssh_password_auth: 'no'
ssh_hardened_ciphers: true

# Firewall rules
firewall_rules:
  - rule: allow
    port: 80
    proto: tcp
    comment: "Allow HTTP"

# Users
user_accounts:
  - username: ansible
    shell: /bin/bash
    groups: [sudo]
```

---

## 🔒 Security Features

✅ SSH hardening (disabled root, key-only auth)
✅ Firewall rules (UFW configuration)
✅ Automatic security updates
✅ User access control
✅ Secure password management (Vault support)
✅ Mail notifications

---

## 📊 Project Statistics

- **Roles:** 22 total (9 essentials + 2 apps + 4 security + 7 monitoring)
- **Playbooks:** 8 execution playbooks
- **Files:** 60+ configuration files
- **Documentation:** 8+ comprehensive guides
- **Lines of Code:** 2000+

## 🎯 Deployment Layers

```
Site.yml → All 22 Roles
├── Essentials (9) → APT, Packages, Users, SSH, etc.
├── Apps (2) → Docker, Rundeck
├── Security (4) → AppArmor, OSSEC, Maldet, Lynis
└── Monitoring (7) → Logs, Metrics, Alerts, Service Monitor
```

---

## 🆘 Quick Troubleshooting

### Test SSH connection
```bash
ansible all -m ping -i inventory/hosts
```

### Check Ansible syntax
```bash
ansible-playbook playbooks/site.yml --syntax-check
```

### Verbose output
```bash
ansible-playbook playbooks/site.yml -vvv
```

### Dry-run (no changes)
```bash
ansible-playbook playbooks/site.yml --check
```

---

## 📚 Full Documentation Structure

```
Documentation/
├── README.md                  - Quick start (you are here)
├── README_FULL.md             - Comprehensive guide
├── IMPLEMENTATION_SUMMARY.md  - Project details
├── QUICK_REFERENCE.sh         - Command reference
└── PROJECT_INDEX.md           - This file
```

---

## 🎓 Learning Path

1. **Start:** Read [README.md](README.md)
2. **Setup:** Configure [inventory/hosts](inventory/hosts)
3. **Explore:** Review [roles/ssh/tasks/main.yml](roles/ssh/tasks/main.yml)
4. **Customize:** Edit [group_vars/all.yml](group_vars/all.yml)
5. **Test:** Run with `--check` flag
6. **Deploy:** Execute playbooks
7. **Learn:** Read [README_FULL.md](README_FULL.md) for details

---

## 💡 Tips

- Use `--check` flag to preview changes before applying
- Use `--tags` to run specific roles
- Use `--diff` to see file differences
- Store secrets in Ansible Vault
- Test on development before production
- Review role defaults before customizing

---

## 🔗 Related Files

### Previous Structure
- [RESTRUCTURING_SUMMARY.md](RESTRUCTURING_SUMMARY.md) - Legacy structure info
- [Agents.md](Agents.md) - Original agent description

### Latest Changes
- All old roles/playbooks replaced with 9 essential roles
- Complete rewrite of documentation
- Added comprehensive examples and templates

---

## ✅ Status

**PROJECT STATUS: COMPLETE AND PRODUCTION READY**

Created: January 18, 2026
Current Version: 1.0

---

**Need help?** Start with [README.md](README.md) or [README_FULL.md](README_FULL.md)
