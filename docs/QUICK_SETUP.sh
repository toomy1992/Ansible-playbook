#!/bin/bash
# Quick Setup Reference
# Location: docs/QUICK_SETUP.sh
# 
# This is a reference script showing the setup workflow
# Not meant to be executed directly - use it as a guide

################################################################################
# FRESH VM SETUP - QUICK REFERENCE
################################################################################

# PREREQUISITE: Add your SSH public key to group_vars/users.yml
cat ~/.ssh/id_ed25519.pub
# Then edit: group_vars/users.yml
# Add the output to: ops_users[0].ssh_keys[0]

################################################################################
# STEP 1: VERIFY CONNECTIVITY
################################################################################

# Ping the VM
ping 192.168.1.100

# Test SSH connection with password (as John)
ssh -v John@192.168.1.100

################################################################################
# STEP 2: RUN SETUP PLAYBOOK
################################################################################

# Navigate to project directory
cd ~/path/to/Ansible-playbook

# Run setup playbook (first time - uses password auth)
# This creates ansible user, sets up SSH keys, hardens SSH
ansible-playbook playbooks/setup.yml \
  -i inventory/sample_inventory.yml \
  -u John \
  -k \
  --ask-become-pass

# What this does:
# - Creates 'ansible' user with passwordless sudo
# - Adds your SSH public key to John account
# - Disables password authentication
# - Hardens SSH configuration
# - Creates 'operators' group

################################################################################
# STEP 3: VERIFY SETUP COMPLETED
################################################################################

# Test connection with ansible user (key-based)
ansible all -i inventory/sample_inventory.yml -m ping

# Check ansible user exists
ansible all -i inventory/sample_inventory.yml -a "id ansible"

# Check SSH is hardened (should show 'no' for PasswordAuthentication)
ansible all -i inventory/sample_inventory.yml -a "sudo sshd -T | grep -E 'passwordauth|pubkeyauth'"

################################################################################
# STEP 4: DEPLOY FULL CONFIGURATION
################################################################################

# Run the main site playbook to deploy all roles
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml

# Or deploy to specific group
ansible-playbook playbooks/docker-hosts.yml -i inventory/sample_inventory.yml

# Or deploy specific roles only
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml --tags=docker
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml --tags=ssh

################################################################################
# TROUBLESHOOTING
################################################################################

# Test SSH directly
ssh -v -i ~/.ssh/id_ed25519 ansible@192.168.1.100

# Check if ansible user was created
ssh -i ~/.ssh/id_ed25519 ansible@192.168.1.100 'id'

# Check SSH config
ssh -i ~/.ssh/id_ed25519 ansible@192.168.1.100 'sudo sshd -T | grep -E "passwordauth|pubkeyauth|permitrootlogin"'

# View setup playbook output in detail
ansible-playbook playbooks/setup.yml \
  -i inventory/sample_inventory.yml \
  -u John \
  -k \
  --ask-become-pass \
  -vvv

# Verify vault configuration
ansible-vault view group_vars/vault.yml

################################################################################
# NEXT STEPS
################################################################################

# 1. You can now run any playbook without password prompts
# 2. SSH is hardened to key-only authentication
# 3. Ansible user can run sudo without password
# 4. Add operational users by editing group_vars/users.yml
# 5. Encrypt vault file for sensitive data
# 6. Run site.yml to deploy full stack

################################################################################
# KEY POINTS
################################################################################

# After setup.yml runs successfully:
# ✓ ansible user created (uid 1000)
# ✓ John user has SSH key auth only
# ✓ SSH password auth disabled
# ✓ Ready for full deployment via site.yml

# Initial Setup (uses passwords):
#   ansible-playbook setup.yml -u John -k --ask-become-pass

# Subsequent Runs (uses SSH keys):
#   ansible-playbook site.yml

################################################################################
# FILES TO CONFIGURE BEFORE SETUP
################################################################################

# 1. Add your SSH public key:
#    nano group_vars/users.yml
#    → ops_users[0].ssh_keys[0]: "ssh-ed25519 AAAA... John@workstation"

# 2. Update inventory with your VM IP:
#    nano inventory/sample_inventory.yml
#    → ansible_host: 192.168.X.X

# 3. Optional - Update vault secrets:
#    nano group_vars/vault.yml
#    ansible-vault encrypt group_vars/vault.yml

################################################################################
