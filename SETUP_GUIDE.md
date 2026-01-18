# VM Setup and Initialization Guide

This guide explains how to initialize a fresh Ubuntu VM for Ansible automation.

## Overview

The setup process uses a dedicated playbook that:
1. **Creates the `ansible` user** - Automation user with passwordless sudo
2. **Configures SSH keys** - Sets up key-only authentication
3. **Hardens SSH** - Disables password authentication
4. **Prepares for automation** - Ready for full playbook deployment

## Prerequisites

### On Your Control Machine (Personal PC)
- Ansible installed
- SSH key generated (for password-less login)
- Access to this repository

### On Fresh Ubuntu VM
- Ubuntu 18.04+ installed
- User `tomek` created during OS installation
- Network connectivity to your PC
- SSH enabled

## Step 1: Prepare Your SSH Keys

### Generate SSH Key (if you don't have one)
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "tomek@workstation"
# or for RSA:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "tomek@workstation"
```

### Get Your SSH Public Key
```bash
cat ~/.ssh/id_ed25519.pub
# Output: ssh-ed25519 AAAA... tomek@workstation
```

## Step 2: Update Configuration Files

### 1. Add Your SSH Public Key to `group_vars/users.yml`

Edit [group_vars/users.yml](../group_vars/users.yml):

```yaml
ops_users:
  - name: tomek
    uid: 1100
    group: operators
    groups:
      - sudo
      - docker
    shell: /bin/bash
    home: /home/tomek
    create_home: true
    comment: "Operations Manager"
    ssh_keys:
      - "ssh-ed25519 AAAA... tomek@workstation"  # ← Add your public key here
```

### 2. Update `inventory/sample_inventory.yml`

Edit [inventory/sample_inventory.yml](../inventory/sample_inventory.yml) with your VM's IP:

```yaml
all:
  children:
    common_ubuntu:
      hosts:
        common-01:
          ansible_host: 192.168.X.X  # ← Update with your VM's IP
          ansible_user: ansible
          ansible_port: 22
```

## Step 3: Run Setup Playbook

This is the critical step that initializes your VM.

### First Time (VM only has 'tomek' user)

From your personal PC:

```bash
cd Ansible-playbook

# Run setup playbook with tomek user and password auth
ansible-playbook playbooks/setup.yml \
  -i inventory/sample_inventory.yml \
  -u tomek \
  -k \
  --ask-become-pass
```

**Flags explained:**
- `-u tomek` - Connect as the initial tomek user
- `-k` - Prompt for tomek's SSH password
- `--ask-become-pass` - Prompt for sudo password (usually same as tomek's password)

**Output should show:**
```
INITIALIZING FRESH UBUNTU VM
=========================================
Host: common-01
OS: Ubuntu 22.04 LTS
Current User: tomek
=========================================
...
VM SETUP COMPLETE
=========================================
Next steps:
1. Add your SSH key to group_vars/users.yml if not already done
2. Run the main playbook:
   ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml

Connection info:
- Automation user: ansible (passwordless sudo)
- SSH: Key-only (password auth disabled)
- Default playbook user: ansible
=========================================
```

### After Setup (ansible user ready)

Once setup completes, you can use the ansible user:

```bash
# Test connectivity with ansible user
ansible all -i inventory/sample_inventory.yml -m ping

# Run full site playbook
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml
```

## What Happens in the Setup Playbook

### 1. Ansible User Creation
- Creates `ansible` user (uid 1000)
- Adds to `sudo` group
- Enables passwordless sudo

### 2. SSH Key Configuration
- Adds your SSH public key to `tomek` user's `.ssh/authorized_keys`
- Sets proper directory permissions (700)
- Sets proper key permissions (600)

### 3. SSH Hardening
- Disables password authentication
- Disables root login
- Enables key-only login
- Hardens ciphers and key exchange algorithms

### 4. User Configuration
- Creates `operators` group (gid 1100)
- Configures tomek with sudo access
- Sets up SSH directory structure

## Troubleshooting

### Connection Refused
**Problem:** SSH connection fails with "Connection refused"

**Solution:**
- Verify VM is running: `ping 192.168.X.X`
- Verify SSH is enabled: `sudo systemctl status ssh` on the VM
- Check firewall: `sudo ufw allow 22/tcp`

### Password Authentication Failed
**Problem:** Getting "Permission denied (publickey,password)"

**Cause:** SSH key not added yet (expected on first run)

**Solution:**
- Use `-k` flag to prompt for password
- Ensure VM has SSH running

### Sudo Password Issues
**Problem:** "Incorrect password" for sudo

**Solution:**
- tomek's sudo password is usually the same as SSH password
- If different, you may need to use `--ask-become-pass`

### Setup Playbook Failed Partway Through
**Problem:** Playbook stopped mid-execution

**Solution:**
1. Identify which step failed in the output
2. Fix the issue (e.g., add SSH key to users.yml)
3. Re-run the setup playbook - it's idempotent (safe to re-run)

### Can't Connect After Setup
**Problem:** Can't SSH into VM after setup playbook

**Cause:** SSH keys weren't properly configured

**Solution:**
1. Check your public key is in `group_vars/users.yml`
2. Verify it's the correct key
3. Try connecting directly: `ssh -i ~/.ssh/id_ed25519 ansible@192.168.X.X`

## Security Considerations

### Passwords
- Initial setup requires tomek's password (unavoidable for fresh VM)
- After setup, all auth is key-based (no password storage)
- Ansible user has passwordless sudo (can be restricted if needed)

### SSH Keys
- Your SSH private key should be protected: `chmod 600 ~/.ssh/id_ed25519`
- Never commit private keys to version control
- Regularly rotate keys for security

### Vault
- Sensitive data (API keys, credentials) should be in `group_vars/vault.yml`
- Encrypt vault file: `ansible-vault encrypt group_vars/vault.yml`
- Always use `--ask-vault-pass` when running playbooks

## Next Steps After Setup

### 1. Run Full Site Playbook
```bash
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml
```

### 2. Deploy Specific Components
```bash
# Essentials only
ansible-playbook playbooks/essentials.yml -i inventory/sample_inventory.yml

# With Docker
ansible-playbook playbooks/docker-hosts.yml -i inventory/sample_inventory.yml

# With Rundeck
ansible-playbook playbooks/rundeck-hosts.yml -i inventory/sample_inventory.yml
```

### 3. Verify Deployment
```bash
# Check ansible user
ansible all -i inventory/sample_inventory.yml -a "whoami"

# Check SSH config
ansible all -i inventory/sample_inventory.yml -a "sudo sshd -T | grep -E 'passwordauth|pubkeyauth'"

# Check users created
ansible all -i inventory/sample_inventory.yml -a "getent passwd ansible tomek"
```

## Advanced: Multiple VMs

To setup multiple VMs:

1. Add all VMs to inventory with their IPs
2. Update `group_vars/users.yml` with all public keys
3. Run setup playbook against all hosts:
```bash
ansible-playbook playbooks/setup.yml -i inventory/sample_inventory.yml -u tomek -k --ask-become-pass
```

## Playbook Idempotency

The setup playbook is **idempotent** - it's safe to run multiple times:
- Creating existing users/groups: No change
- Adding existing SSH keys: No change
- SSH config already hardened: No change

This means you can safely re-run if something fails!

## Architecture Diagram

```
FRESH VM (just installed)
├─ User: tomek (password auth)
└─ SSH: Allowed passwords
       ↓
   [RUN: setup.yml -u tomek -k]
       ↓
CONFIGURED VM (ready for automation)
├─ User: tomek (SSH key auth only)
├─ User: ansible (created, passwordless sudo)
└─ SSH: Key-only, hardened config
       ↓
   [RUN: site.yml -u ansible]
       ↓
FULLY DEPLOYED VM (all roles applied)
├─ Essentials configured
├─ Security hardened
├─ Monitoring enabled
├─ Apps installed (optional)
└─ Ready for production
```

## FAQ

### Q: Do I need to run setup on every VM?
**A:** Yes, at least once per fresh VM installation.

### Q: Can I customize the setup playbook?
**A:** Yes, edit [playbooks/setup.yml](setup.yml) to change user names, UIDs, etc.

### Q: What if I have an existing VM without setup?
**A:** You can still run setup.yml if the VM has a sudo-capable user.

### Q: How do I add more users?
**A:** Edit `group_vars/users.yml` and add to `ops_users` list, then re-run setup.

### Q: Can I disable passwordless sudo?
**A:** Yes, in `group_vars/all.yml`, change `nopasswd: true` to `nopasswd: false`.

