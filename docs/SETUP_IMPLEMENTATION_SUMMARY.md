# Fresh VM Setup Implementation - Summary

This document summarizes the new setup workflow for initializing fresh Ubuntu VMs.

## Problem Solved

When deploying to a fresh Ubuntu VM that only has the `John` user (created during OS installation), we needed:

1. **Initial SSH access** - Using password auth (only available method initially)
2. **Automation user creation** - Create `ansible` user for automated playbooks
3. **SSH hardening** - Remove password auth, enable key-only login
4. **User configuration** - Set up `John` and `ansible` users properly
5. **Clean, repeatable process** - Work from your personal PC

## Solution: Multi-Stage Initialization

### Stage 1: Fresh VM (Before setup.yml)
```
Fresh Ubuntu Install
├─ User: John (password authentication enabled)
├─ SSH: Password-based login allowed
└─ Ready: For setup.yml deployment
```

### Stage 2: After setup.yml
```
Initialized VM (Ready for automation)
├─ User: John (SSH key-only auth)
├─ User: ansible (created, passwordless sudo)
├─ SSH: Hardened, key-only, secure
└─ Ready: For full site.yml deployment
```

### Stage 3: After site.yml
```
Fully Configured Production Server
├─ Essentials: APT, Packages, Users, SSH, etc.
├─ Security: AppArmor, OSSEC, Maldet, Lynis
├─ Monitoring: Loki, Prometheus, Alertmanager, Monit
├─ Apps: Docker and/or Rundeck (as configured)
└─ Status: Production-ready
```

## New Files Created

### 1. **playbooks/setup.yml** (Main Setup Playbook)
- Runs from your personal PC using password auth
- Creates `ansible` user (uid 1000, passwordless sudo)
- Configures SSH keys for `John` and operational users
- Hardens SSH (disables password auth)
- Tag: `setup`

**Usage:**
```bash
ansible-playbook playbooks/setup.yml \
  -i inventory/sample_inventory.yml \
  -u John \
  -k \
  --ask-become-pass
```

### 2. **SETUP_GUIDE.md** (Comprehensive Setup Instructions)
- Step-by-step setup process
- Prerequisite verification
- Configuration file updates
- Troubleshooting guide
- Security considerations
- Next steps after setup

### 3. **docs/QUICK_SETUP.sh** (Quick Reference)
- Bash-based command reference
- All setup and deployment commands
- Troubleshooting commands
- Verification steps

### 4. **docs/WORKFLOW.md** (Architecture & Workflow)
- Visual workflow diagrams
- Setup.yml playbook details
- Playbook execution order
- Troubleshooting flowchart
- Multi-VM deployment guide
- Command reference

### 5. **docs/PRE_FLIGHT_CHECKLIST.md** (Verification Checklist)
- Pre-setup verification items
- Configuration file checklist
- Post-setup verification tests
- Success criteria
- Quick verification commands

## Key Features

### ✅ Password-Only to Key-Only Auth
```
Initial: SSH with password (John@VM)
  ↓ [setup.yml]
Final: SSH with key-only (ansible@VM, John@VM with keys)
```

### ✅ Automation User (ansible) Creation
- UID: 1000
- Group: ansible  
- Sudo: Passwordless
- Purpose: Runs automated playbooks

### ✅ Operational User (John) Hardening
- Converted to SSH key-only auth
- Added to sudo group
- SSH directory properly configured

### ✅ SSH Hardening Applied
- Password authentication: DISABLED
- Root login: DISABLED  
- Key exchange: Hardened algorithms
- Ciphers: Strong cryptography

### ✅ Idempotent Design
- Safe to re-run setup.yml multiple times
- Creates users only if missing
- Updates configs only if needed
- No data loss on re-runs

## Updated Files

### **group_vars/all.yml**
- Added reference to users_ops role variables
- Documented ansible user configuration
- Noted users.yml reference for SSH keys

### **group_vars/users.yml**  
- Added `ops_user_groups` (operators group)
- Added `ops_users` (John user config with SSH key placeholder)
- Added `ops_sudo_users` (John sudo access)
- Setup instructions documented

### **playbooks/site.yml**
- Added conditional role execution
- Docker role: Runs on docker_hosts, ubuntu_desktop groups only
- Rundeck role: Runs on rundeck_hosts group only

### **README.md**
- Added "Quick Start" section with setup.yml reference
- Links to SETUP_GUIDE.md for detailed instructions
- Updated with setup workflow information

## Workflow Summary

### For Fresh VM Deployment:

```bash
# STEP 1: Configure (Edit these files)
nano group_vars/users.yml          # Add your SSH public key
nano inventory/sample_inventory.yml # Update VM IP address

# STEP 2: Setup (Run from personal PC)
ansible-playbook playbooks/setup.yml \
  -i inventory/sample_inventory.yml \
  -u John \
  -k \
  --ask-become-pass

# STEP 3: Verify (Check setup worked)
ansible all -i inventory/sample_inventory.yml -m ping

# STEP 4: Deploy (Full configuration)
ansible-playbook playbooks/site.yml \
  -i inventory/sample_inventory.yml
```

## Important Notes

### Before Running setup.yml:
1. ✅ Add your SSH public key to `group_vars/users.yml`
2. ✅ Update VM IP in `inventory/sample_inventory.yml`
3. ✅ Have John's password available (prompted with -k flag)
4. ✅ Ensure VM is reachable via SSH

### During setup.yml Execution:
- First run only: Needs password auth (use -k)
- Subsequent runs: Can use key-based auth
- Idempotent: Safe to re-run if needed
- Duration: ~1-2 minutes per VM

### After setup.yml Completes:
- ✅ ansible user created and ready
- ✅ John user hardened with SSH keys
- ✅ SSH password auth disabled
- ✅ Ready for site.yml deployment
- ✅ All subsequent runs use key auth (no -k needed)

## Security Benefits

### Eliminated Password Storage
- No plaintext passwords in Ansible
- All auth via SSH keys
- Vault for sensitive data only

### SSH Hardening Enforced
- Password authentication disabled
- Root login disabled
- Strong ciphers and key exchange
- Best practice SSH config

### Automation User Isolation
- Dedicated user for Ansible
- Passwordless sudo for automation
- Separate from human users
- Easy to audit and revoke

### Human User Protection
- SSH key-only access for human users
- Password auth eliminated after setup
- Can revoke specific keys if needed
- Audit trail of who has access

## Deployment Strategies

### Single VM:
```bash
# Update files, run setup, run site
ansible-playbook playbooks/setup.yml -i inventory/sample_inventory.yml -u John -k --ask-become-pass
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml
```

### Multiple VMs (Parallel):
```bash
# All VMs at once (efficient for fleet deployment)
ansible-playbook playbooks/setup.yml -i inventory/sample_inventory.yml -u John -k --ask-become-pass
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml
```

### Selective Groups:
```bash
# Only docker hosts
ansible-playbook playbooks/docker-hosts.yml -i inventory/sample_inventory.yml

# Only rundeck hosts
ansible-playbook playbooks/rundeck-hosts.yml -i inventory/sample_inventory.yml

# Only common servers
ansible-playbook playbooks/common-hosts.yml -i inventory/sample_inventory.yml
```

## Files for Reference

| File | Purpose |
|------|---------|
| [SETUP_GUIDE.md](../SETUP_GUIDE.md) | Detailed setup walkthrough |
| [docs/WORKFLOW.md](WORKFLOW.md) | Architecture & workflow diagrams |
| [docs/QUICK_SETUP.sh](QUICK_SETUP.sh) | Command reference |
| [docs/PRE_FLIGHT_CHECKLIST.md](PRE_FLIGHT_CHECKLIST.md) | Verification checklist |
| [playbooks/setup.yml](../playbooks/setup.yml) | The setup playbook |
| [group_vars/users.yml](../group_vars/users.yml) | SSH keys configuration |
| [inventory/sample_inventory.yml](../inventory/sample_inventory.yml) | Host inventory |

## Support Resources

1. **Getting Started**: Read [SETUP_GUIDE.md](../SETUP_GUIDE.md)
2. **Visual Reference**: Check [docs/WORKFLOW.md](WORKFLOW.md)
3. **Quick Commands**: See [docs/QUICK_SETUP.sh](QUICK_SETUP.sh)
4. **Before Running**: Complete [docs/PRE_FLIGHT_CHECKLIST.md](PRE_FLIGHT_CHECKLIST.md)
5. **Troubleshooting**: Review troubleshooting sections in SETUP_GUIDE.md

## Next Steps

1. ✅ Add your SSH public key to `group_vars/users.yml`
2. ✅ Update VM IP in `inventory/sample_inventory.yml`
3. ✅ Run `playbooks/setup.yml` on fresh VM
4. ✅ Verify with `ansible all -m ping`
5. ✅ Deploy with `playbooks/site.yml`
6. ✅ Enjoy fully configured production server! 🎉

