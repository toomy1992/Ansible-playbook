# Security Roles Implementation Guide

## Overview

The Security layer adds comprehensive hardening and monitoring capabilities to the Ansible framework:
- **AppArmor**: Mandatory Access Control (MAC) for process confinement
- **Integrity Monitoring**: OSSEC file integrity monitoring with real-time alerts
- **Malware Scanning**: Maldet daily malware detection and quarantine
- **Security Audits**: Lynis daily security audits with compliance reporting

## Architecture

```
Security Layer (15 total roles)
├── Essentials (9)
│   ├── APT, Packages, Users, SSH
│   ├── Timezone, Hostname, Firewall, Mail
│   └── Updates
├── Apps & Services (2)
│   ├── Docker
│   └── Rundeck
└── Security (4)
    ├── AppArmor - Kernel MAC
    ├── Integrity Monitoring - OSSEC
    ├── Malware Scanning - Maldet
    └── Security Audits - Lynis
```

## Security Roles Details

### 1. AppArmor Role

**Purpose**: Implement Mandatory Access Control (MAC) for process confinement

**Key Features**:
- Installs AppArmor kernel module and utilities
- Loads default Ubuntu AppArmor profiles
- Supports custom profile creation
- Profile enforcement and complain modes
- System hardening via sysctl parameters

**Key Variables**:
```yaml
apparmor_enforce_profiles: []      # Profiles to enforce
apparmor_complain_profiles: []     # Profiles in complain mode
apparmor_custom_profiles: []       # Custom profile definitions
```

**Usage**:
```bash
# Deploy AppArmor only
ansible-playbook playbooks/site.yml --tags apparmor

# Enforce specific profiles
ansible-playbook playbooks/site.yml --tags apparmor \
  -e apparmor_enforce_profiles="[usr.bin.man, usr.sbin.tcpdump]"
```

**Verification**:
```bash
sudo aa-status                  # View profile status
sudo aa-enforce /path/to/profile    # Enforce a profile
sudo aa-complain /path/to/profile   # Set complain mode
```

**Custom Profile Example**:
```yaml
apparmor_custom_profiles:
  - name: nginx
    binary: nginx
```

---

### 2. Integrity Monitoring (OSSEC)

**Purpose**: File integrity monitoring with real-time alerts and reporting

**Key Features**:
- Installs OSSEC from source (v3.7.0+)
- Monitors critical directories (/etc, /bin, /usr/bin, etc.)
- Real-time file change detection
- Daily integrity reports with email notifications
- Log rotation and audit trail maintenance

**Key Variables**:
```yaml
ossec_version: 3.7.0                     # OSSEC version
ossec_email_notifications: false         # Enable email alerts
ossec_admin_email: "root"                # Alert recipient
ossec_report_hour: 6                     # Daily report time
ossec_report_minute: 0
ossec_monitored_paths:                   # Directories to monitor
  - /etc
  - /bin
  - /usr/bin
  - /root
ossec_syscheck_interval: 3600            # Scan interval (seconds)
ossec_syscheck_scan_on_start: "yes"      # Initial scan
ossec_syscheck_realtime: "yes"           # Real-time monitoring
```

**Usage**:
```bash
# Deploy OSSEC with email alerts
ansible-playbook playbooks/security-full.yml --tags integrity-monitoring \
  -e ossec_email_notifications=true \
  -e ossec_admin_email="admin@example.com"

# Monitor additional directories
ansible-playbook playbooks/security-full.yml --tags integrity-monitoring \
  -e ossec_monitored_paths="[/etc,/root,/opt,/home]"
```

**Verification**:
```bash
sudo /var/ossec/bin/agent_control -l         # List agents
sudo /var/ossec/bin/agent_control -i         # Info
tail -f /var/ossec/logs/alerts/alerts.log    # Monitor alerts
ls /var/ossec/logs/reports/                  # View reports
```

**Monitoring Output**:
- Alert Log: `/var/ossec/logs/alerts/alerts.log`
- Reports: `/var/ossec/logs/reports/`
- Daily Summary: `/var/ossec/logs/reports/integrity_report_*.txt`

---

### 3. Malware Scanning (Maldet)

**Purpose**: Daily malware detection and quarantine

**Key Features**:
- Installs Linux Malware Detect (Maldet)
- Daily scheduled scans of configurable paths
- Automatic signature database updates
- Quarantine support for detected malware
- Daily scan reports with email delivery
- Report retention (30-day rolling window)

**Key Variables**:
```yaml
maldet_version: latest                    # Maldet version
maldet_email_notifications: false         # Email alerts
maldet_admin_email: "root"                # Alert recipient
maldet_scan_hour: 2                       # Daily scan time
maldet_scan_minute: 0
maldet_update_hour: 0                     # Update schedule
maldet_update_minute: 30
maldet_scan_paths:                        # Scan targets
  - /home
  - /var/www
  - /root
maldet_quarantine_suspicious: true        # Auto-quarantine
maldet_alert_on_detection: true           # Alert on finds
maldet_scan_timeout: 3600                 # Max scan time
```

**Usage**:
```bash
# Deploy Maldet with email alerts
ansible-playbook playbooks/security-full.yml --tags malware-scanning \
  -e maldet_email_notifications=true \
  -e maldet_admin_email="admin@example.com"

# Expand scan directories
ansible-playbook playbooks/security-full.yml --tags malware-scanning \
  -e maldet_scan_paths="[/home,/var/www,/opt,/root]"

# Manual scan
sudo /usr/local/sbin/maldet -a /home /var/www
```

**Verification**:
```bash
sudo /usr/local/sbin/maldet --version      # Check version
sudo /usr/local/sbin/maldet --update       # Update signatures
ls -l /var/log/maldet-reports/             # View scan reports
sudo /usr/local/sbin/maldet -i             # Last session info
```

**Daily Reports**:
- Location: `/var/log/maldet-reports/maldet_report_*.txt`
- Retention: 30 days automatic cleanup
- Contents: Scan summary, detections, quarantine info

---

### 4. Security Audits (Lynis)

**Purpose**: Daily security compliance audits and hardening suggestions

**Key Features**:
- Installs Lynis security audit framework
- Daily automated security audits
- Compliance checking (CIS, PCI-DSS, etc.)
- Hardening suggestions based on audit results
- Daily summary reports with email delivery
- Baseline audit for initial assessment

**Key Variables**:
```yaml
lynis_email_notifications: false          # Email reports
lynis_admin_email: "root"                 # Report recipient
lynis_audit_hour: 4                       # Daily audit time
lynis_audit_minute: 0
lynis_auditor_name: "Security Team"       # Audit attribution
lynis_report_title: "System Security Audit Report"
lynis_quiet_mode: "0"                     # Verbose output
lynis_deep_inspection: "0"                # Deep scanning
lynis_audit_options: []                   # Custom flags
lynis_audit_categories:                   # Audit areas
  - boot_services
  - file_permissions
  - system_tools
  - malware
  - security_compliance
```

**Usage**:
```bash
# Deploy Lynis with email reports
ansible-playbook playbooks/security-full.yml --tags security-audits \
  -e lynis_email_notifications=true \
  -e lynis_admin_email="admin@example.com"

# Run deep inspection
ansible-playbook playbooks/security-full.yml --tags security-audits \
  -e lynis_deep_inspection="1"

# Manual audit
sudo /usr/sbin/lynis audit system --quiet
```

**Verification**:
```bash
sudo /usr/sbin/lynis --version             # Check version
sudo /usr/sbin/lynis audit system          # Manual audit
ls /var/log/lynis-reports/                 # View reports
grep "^\[W\]" /var/log/lynis.log           # View warnings
grep "^\[S\]" /var/log/lynis.log           # View suggestions
```

**Audit Output**:
- Full Reports: `/var/log/lynis-reports/lynis_audit_*.txt`
- Summary Reports: `/var/log/lynis-reports/audit_summary_*.txt`
- Audit Log: `/var/log/lynis.log`
- Baseline Audit: `/var/log/lynis-reports/baseline_audit_*.txt`

---

## Deployment Scenarios

### Scenario 1: Full Security Stack

```bash
# Deploy all security roles to all hosts
ansible-playbook playbooks/security-full.yml

# Deploy with email alerts
ansible-playbook playbooks/security-full.yml \
  -e ossec_email_notifications=true \
  -e maldet_email_notifications=true \
  -e lynis_email_notifications=true \
  -e ossec_admin_email="security@example.com" \
  -e maldet_admin_email="security@example.com" \
  -e lynis_admin_email="security@example.com"
```

### Scenario 2: Production Hardening

```bash
# Apply all security roles via site.yml with security tag
ansible-playbook playbooks/site.yml --tags security

# Alternative: Just security roles
ansible-playbook playbooks/security-full.yml
```

### Scenario 3: Selective Security Deployment

```bash
# Only AppArmor and Firewall
ansible-playbook playbooks/site.yml --tags "apparmor,firewall"

# Only monitoring (OSSEC + Maldet)
ansible-playbook playbooks/site.yml --tags "integrity-monitoring,malware-scanning"

# Only audits (Lynis)
ansible-playbook playbooks/site.yml --tags "security-audits"
```

### Scenario 4: Staged Deployment (Low to High Risk)

```bash
# Stage 1: Audit only (lowest risk)
ansible-playbook playbooks/security-full.yml --tags "security-audits"

# Stage 2: Monitoring (monitoring data only)
ansible-playbook playbooks/security-full.yml --tags "integrity-monitoring,malware-scanning"

# Stage 3: AppArmor (kernel-level control)
ansible-playbook playbooks/security-full.yml --tags "apparmor"
```

---

## Integration with Essentials

### Mail Notifications

All security roles can leverage the **mail role** for notifications:

```yaml
# Configure mail role first (group_vars/all.yml)
mail_enabled: true
mail_relay_host: "mail.example.com"
mail_relay_port: 587
mail_relay_user: "notifications@example.com"

# Then enable notifications in security roles
ossec_email_notifications: true
maldet_email_notifications: true
lynis_email_notifications: true
```

### SSH Integration

The **SSH hardening** from the ssh role pairs well with AppArmor:

```bash
# Deploy hardened SSH + AppArmor confinement
ansible-playbook playbooks/site.yml --tags "ssh,apparmor"
```

### Firewall Integration

**UFW firewall** can whitelist monitoring tools:

```yaml
# In group_vars/all.yml
firewall_rules:
  - rule: allow
    name: SSH
    port: 22
    proto: tcp
  # OSSEC server communication (if using manager mode)
  - rule: allow
    name: OSSEC
    port: 1514
    proto: tcp
```

---

## Monitoring and Reporting

### Daily Report Schedule

```
Time        Role                Action
00:30       Maldet              Update signatures
02:00       Maldet              Daily scan
04:00       Lynis               Security audit
06:00       OSSEC               Integrity report
```

### Email Report Contents

**OSSEC Report**:
```
OSSEC Integrity Monitoring Report
==================================
Generated: 2024-01-15 06:00:00
Hostname: server1

Alert Summary:
- File added: 3
- File modified: 1
- File deleted: 0
```

**Maldet Report**:
```
Maldet Malware Scan Report
==========================
Scanning: /home /var/www /root
Results: Clean (0 detections)
```

**Lynis Report**:
```
Lynis Daily Security Audit Summary
===================================
Warnings found: 2
Suggestions found: 5
Hardening index: 78/100
```

---

## Security Best Practices

### 1. Gradual Rollout
- Start with Lynis audits to identify issues
- Then deploy AppArmor in complain mode
- Enable OSSEC monitoring
- Finally enable Maldet with quarantine

### 2. Email Configuration
- Create dedicated notification email address
- Implement mail filtering rules for alerts
- Archive reports for compliance
- Review daily summaries

### 3. Custom AppArmor Profiles
```yaml
# For custom applications
apparmor_custom_profiles:
  - name: myapp
    binary: myapp
```

### 4. Monitored Paths Strategy
```yaml
# Critical paths
ossec_monitored_paths:
  - /etc               # Config files
  - /bin               # System binaries
  - /usr/bin           # User binaries
  - /root              # Root home
  - /home              # User homes
```

### 5. Malware Scan Optimization
```yaml
# Avoid scanning unnecessary paths
maldet_scan_paths:
  - /home
  - /var/www
  - /opt

# Exclude cache directories
maldet_ignorepaths:
  - /var/cache
  - /tmp
  - /proc
```

---

## Troubleshooting

### OSSEC not reporting alerts

```bash
# Check OSSEC service
sudo systemctl status ossec
sudo /var/ossec/bin/agent_control -i

# Check configuration
sudo /var/ossec/bin/ossec-control status

# Test email
echo "Test" | mail -s "Test" admin@example.com
```

### Maldet scan slow

```bash
# Check current scan
sudo /usr/local/sbin/maldet -l

# Optimize: Reduce file size minimum
maldet_min_file_size: 1000  # Skip small files

# Or reduce scan paths in group_vars
maldet_scan_paths: [/var/www]  # Focus on web
```

### Lynis reports not generating

```bash
# Check Lynis installation
sudo /usr/sbin/lynis --version

# Run manual audit
sudo /usr/sbin/lynis audit system --quiet

# Check permissions
ls -la /var/log/lynis-reports/
```

### AppArmor profiles not loading

```bash
# Check kernel support
grep -i apparmor /boot/config-$(uname -r)

# View profile status
sudo aa-status

# Reload all profiles
sudo apparmor_parser -r /etc/apparmor.d/*
```

---

## Next Steps

1. **Deploy full security stack** to test environment
2. **Review daily reports** for the first week
3. **Implement hardening suggestions** from Lynis
4. **Adjust scan schedules** if resource-heavy
5. **Integrate with SIEM/monitoring** systems if available
6. **Regular backup** of OSSEC and Lynis reports
7. **Quarterly audits** of AppArmor profiles

---

## References

- [AppArmor Documentation](https://wiki.ubuntu.com/AppArmor)
- [OSSEC Documentation](https://www.ossec.net/)
- [Maldet Documentation](https://www.rfxn.com/projects/linux-malware-detect/)
- [Lynis Security Audit](https://cisofy.com/lynis/)
