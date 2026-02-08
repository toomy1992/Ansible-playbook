# Pre-Flight Checklist for Ansible Deployment

Use this checklist before running any playbooks to ensure everything is ready.

## ✅ Before First Setup (Fresh VM)

### On Your Personal PC / Control Machine

- [ ] **Ansible Installed**
  ```bash
  ansible --version
  # Should show: Ansible 2.9+ or 2.10+
  ```

- [ ] **SSH Key Generated**
  ```bash
  ls -la ~/.ssh/id_ed25519
  # or id_rsa if using RSA
  ```

- [ ] **SSH Public Key Copied**
  ```bash
  cat ~/.ssh/id_ed25519.pub
  # Copy this output for next step
  ```

- [ ] **Repository Cloned/Downloaded**
  ```bash
  ls -la ~/Ansible-playbook
  # Should show: roles/, playbooks/, inventory/, group_vars/, etc.
  ```

- [ ] **Network Connectivity to VM**
  ```bash
  ping 192.168.X.X
  # VM should respond to pings
  ```

### On Fresh Ubuntu VM

- [ ] **Ubuntu Version Checked**
  ```bash
  lsb_release -a
  # Should be 18.04 LTS or newer
  ```

- [ ] **SSH Service Running**
  ```bash
  sudo systemctl status ssh
  # Should show: active (running)
  ```

- [ ] **Firewall Allows SSH (if enabled)**
  ```bash
  sudo ufw allow 22/tcp
  ```

- [ ] **User 'John' Exists**
  ```bash
  id John
  # Should return user info
  ```

- [ ] **Network Connectivity from VM**
  ```bash
  ping 8.8.8.8
  # VM should have internet access
  ```

## ✅ Configuration Files Updated

### Step 1: Update Inventory

- [ ] **inventory/sample_inventory.yml Updated**
  - [ ] All VM IPs updated correctly (192.168.X.X)
  - [ ] Hostnames match your environment
  - [ ] Groups assigned correctly (docker_hosts, etc.)

  ```bash
  # Verify syntax
  ansible-inventory -i inventory/sample_inventory.yml --list
  # Should show JSON output with all hosts
  ```

### Step 2: Update SSH Keys

- [ ] **group_vars/users.yml Updated**
  - [ ] SSH public key added to `ops_users[0].ssh_keys[0]`
  - [ ] Username is correct (John)
  - [ ] SSH key format is correct (starts with ssh-ed25519 or ssh-rsa)

  ```bash
  # Check key is in file
  grep "ssh-ed25519\|ssh-rsa" group_vars/users.yml
  # Should show your SSH public key
  ```

### Step 3: Verify Other Configs (Optional)

- [ ] **group_vars/all.yml** - Reviewed (optional)
  - [ ] System timezone correct
  - [ ] Hostname settings reviewed
  - [ ] Firewall rules customized if needed

- [ ] **group_vars/vault.yml** - Reviewed (optional)
  - [ ] Encrypted if contains sensitive data
  - [ ] Passwords/keys updated if needed

## ✅ Pre-Setup Verification

Run these commands to verify everything is ready:

```bash
# Test Ansible installation
ansible --version

# Verify inventory syntax
ansible-inventory -i inventory/sample_inventory.yml --list

# Check SSH public key exists
cat ~/.ssh/id_ed25519.pub

# Verify group_vars files exist
ls -la group_vars/

# Test network connectivity to VM
ping 192.168.X.X
```

## ✅ Ready to Run setup.yml

Before running setup playbook, verify:

- [ ] All above items checked ✓
- [ ] Network connectivity confirmed
- [ ] SSH public key in group_vars/users.yml
- [ ] Inventory IPs correct
- [ ] John password available (will be prompted)

## ✅ Running setup.yml

Execute setup playbook:

```bash
cd ~/Ansible-playbook

ansible-playbook playbooks/setup.yml \
  -i inventory/sample_inventory.yml \
  -u John \
  -k \
  --ask-become-pass
```

Monitor output for:
- [ ] "INITIALIZING FRESH UBUNTU VM" message
- [ ] "Create operational user groups" task
- [ ] "Create operational users" task  
- [ ] "Add authorized SSH keys" task
- [ ] "Configure sudo access" task
- [ ] "VM SETUP COMPLETE" message

If any task fails:
- [ ] Review error message
- [ ] Check configuration files
- [ ] Fix issue
- [ ] Re-run setup (it's idempotent)

## ✅ Post-Setup Verification

After setup.yml completes successfully:

```bash
# Test ansible user connection
ansible all -i inventory/sample_inventory.yml -m ping
# Should show: "pong" for all hosts

# Verify ansible user created
ansible all -i inventory/sample_inventory.yml -a "id ansible"
# Should show: uid=1000(ansible) gid=1000(ansible)

# Check SSH hardening (password auth should be 'no')
ansible all -i inventory/sample_inventory.yml -a "sudo sshd -T | grep passwordauth"
# Should show: passwordauthentication no

# Verify John user has SSH key access
ansible all -i inventory/sample_inventory.yml -a "wc -l ~/.ssh/authorized_keys"
# Should show: 1 (at least one SSH key)
```

All above should succeed ✓

## ✅ Ready for Full Deployment

After setup.yml succeeds and verifications pass:

```bash
# Deploy full configuration
ansible-playbook playbooks/site.yml \
  -i inventory/sample_inventory.yml
```

Or deploy to specific group:

```bash
# Docker hosts only
ansible-playbook playbooks/docker-hosts.yml \
  -i inventory/sample_inventory.yml

# Common servers only  
ansible-playbook playbooks/common-hosts.yml \
  -i inventory/sample_inventory.yml
```

## ✅ Post-Deployment Verification

After site.yml completes:

```bash
# Check key services running
ansible all -i inventory/sample_inventory.yml -a "systemctl status ssh"

# Verify users created
ansible all -i inventory/sample_inventory.yml -a "getent passwd ansible John"

# Check firewall rules applied
ansible all -i inventory/sample_inventory.yml -a "sudo ufw status"

# Verify monitoring installed (if included)
ansible all -i inventory/sample_inventory.yml -a "systemctl status prometheus" -l docker_hosts
ansible all -i inventory/sample_inventory.yml -a "systemctl status loki" -l docker_hosts

# Check logs
ansible all -i inventory/sample_inventory.yml -a "sudo journalctl -xe -n 50"
```

## ✅ Troubleshooting Checklist

If something fails, check:

### setup.yml Fails
- [ ] SSH public key is in group_vars/users.yml
- [ ] Inventory IP is correct
- [ ] Can SSH manually: `ssh -v John@IP`
- [ ] John password is typed correctly
- [ ] User has sudo access on VM
- [ ] SSH service is running: `sudo systemctl status ssh`

### site.yml Fails
- [ ] setup.yml completed successfully before running site.yml
- [ ] Using correct inventory file: `-i inventory/sample_inventory.yml`
- [ ] SSH keys still work: `ssh -i ~/.ssh/id_ed25519 ansible@IP`
- [ ] Hosts are reachable: `ansible all -m ping`
- [ ] Check specific role error and review role tasks

### Connection Issues
- [ ] VM is powered on and has network access
- [ ] Ping works: `ping 192.168.X.X`
- [ ] SSH works: `ssh -v John@IP`
- [ ] Check firewall: `sudo ufw allow 22/tcp`
- [ ] Check SSH running: `sudo systemctl status ssh`

### Permission Issues
- [ ] John has sudo access (default on fresh install)
- [ ] ansible user created successfully
- [ ] SSH keys have correct permissions (600)
- [ ] .ssh directory has correct permissions (700)

## 📋 Quick Verification Commands

Copy and run these after each step:

```bash
# After setup.yml
ansible all -i inventory/sample_inventory.yml -m ping

# After site.yml
ansible all -i inventory/sample_inventory.yml -m setup | jq '.ansible_facts | {os_family, distribution, distribution_version}'

# Check all users
ansible all -i inventory/sample_inventory.yml -a "getent passwd | grep -E 'ansible|John'"

# Verify SSH hardening
ansible all -i inventory/sample_inventory.yml -a "sudo sshd -T | grep -E 'passwordauth|rootlogin|pubkeyauth'"

# Check deployed roles
ansible all -i inventory/sample_inventory.yml -a "ls -d /etc/ansible/roles/*" 2>/dev/null || echo "Roles deployed via tasks"
```

## 🎯 Success Criteria

✅ **Deployment is successful when:**

1. **setup.yml completes** without errors
   - [ ] ansible user created
   - [ ] SSH hardened
   - [ ] SSH keys deployed

2. **site.yml completes** without errors
   - [ ] All roles apply successfully
   - [ ] No failed tasks reported

3. **Verification passes**
   - [ ] `ansible all -m ping` shows pong for all hosts
   - [ ] SSH keys work without passwords
   - [ ] Users are created correctly
   - [ ] Services are running

4. **System is stable**
   - [ ] Can SSH as ansible user
   - [ ] Passwordless sudo works
   - [ ] All services start on boot
   - [ ] Security hardening applied

## 📞 Need Help?

If something doesn't work:

1. Check [SETUP_GUIDE.md](../SETUP_GUIDE.md) for detailed instructions
2. Review [WORKFLOW.md](WORKFLOW.md) for architecture and flow
3. Check playbook output for specific error messages
4. Run with verbose flag: `-vvv` for debugging
5. Review specific role's README for detailed info

