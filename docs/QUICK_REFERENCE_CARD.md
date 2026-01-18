# Quick Reference Card - Fresh VM Setup

## 📋 Setup in 4 Steps

```
┌─────────────────────────────────────────────────────────┐
│ STEP 1: CONFIGURE (5 minutes)                           │
├─────────────────────────────────────────────────────────┤
│ 1. Get your SSH public key:                             │
│    cat ~/.ssh/id_ed25519.pub                            │
│                                                         │
│ 2. Edit: group_vars/users.yml                           │
│    Replace "ssh-ed25519 AAAA... tomek@workstation"     │
│    With your actual SSH public key                      │
│                                                         │
│ 3. Edit: inventory/sample_inventory.yml                 │
│    Replace: ansible_host: 192.168.1.100                │
│    With your VM's IP address                            │
└─────────────────────────────────────────────────────────┘

                      ⬇️  READY? Continue...

┌─────────────────────────────────────────────────────────┐
│ STEP 2: SETUP (2-3 minutes)                             │
├─────────────────────────────────────────────────────────┤
│ Run this command from your personal PC:                 │
│                                                         │
│ $ ansible-playbook playbooks/setup.yml \               │
│     -i inventory/sample_inventory.yml \                 │
│     -u tomek \                                          │
│     -k \                                                │
│     --ask-become-pass                                   │
│                                                         │
│ When prompted:                                          │
│ • SSH password: (tomek's password)                     │
│ • Become password: (usually same)                       │
│                                                         │
│ Expected output: "VM SETUP COMPLETE"                    │
└─────────────────────────────────────────────────────────┘

                      ⬇️  VERIFY...

┌─────────────────────────────────────────────────────────┐
│ STEP 3: VERIFY (1 minute)                               │
├─────────────────────────────────────────────────────────┤
│ Test ansible user works:                                │
│                                                         │
│ $ ansible all \                                         │
│     -i inventory/sample_inventory.yml \                 │
│     -m ping                                             │
│                                                         │
│ Expected output: "pong" for all hosts                   │
│ If YES ✅ → Go to STEP 4                               │
│ If NO  ❌ → Check TROUBLESHOOTING section              │
└─────────────────────────────────────────────────────────┘

                      ⬇️  DEPLOY...

┌─────────────────────────────────────────────────────────┐
│ STEP 4: DEPLOY (5-10 minutes)                           │
├─────────────────────────────────────────────────────────┤
│ Deploy full configuration:                              │
│                                                         │
│ $ ansible-playbook playbooks/site.yml \                │
│     -i inventory/sample_inventory.yml                   │
│                                                         │
│ OR deploy to specific group:                            │
│                                                         │
│ $ ansible-playbook playbooks/docker-hosts.yml \         │
│     -i inventory/sample_inventory.yml                   │
│                                                         │
│ $ ansible-playbook playbooks/rundeck-hosts.yml \        │
│     -i inventory/sample_inventory.yml                   │
│                                                         │
│ Expected: All tasks complete with "ok" or "changed"    │
│                                                         │
│ 🎉 Done! VM is now fully configured!                   │
└─────────────────────────────────────────────────────────┘
```

## 🔑 Key Credentials

| Credential | Value | Used For |
|-----------|-------|----------|
| **tomek** (initial) | password | First SSH connection |
| **ansible** (created) | SSH key | All playbooks after setup |
| **tomek** (after setup) | SSH key | Operational access |

## 📁 Files to Edit (Before Step 2)

### group_vars/users.yml
```yaml
ops_users:
  - name: tomek
    ssh_keys:
      - "ssh-ed25519 AAAA... tomek@workstation"  # ← PASTE YOUR KEY HERE
```

### inventory/sample_inventory.yml
```yaml
common_ubuntu:
  hosts:
    common-01:
      ansible_host: 192.168.X.X  # ← UPDATE THIS IP
```

## 🚀 Command Cheat Sheet

### First Time (Fresh VM)
```bash
# Step 2: Setup with password
ansible-playbook playbooks/setup.yml \
  -i inventory/sample_inventory.yml \
  -u tomek -k --ask-become-pass

# Step 3: Verify
ansible all -i inventory/sample_inventory.yml -m ping

# Step 4: Deploy
ansible-playbook playbooks/site.yml \
  -i inventory/sample_inventory.yml
```

### Future Runs (After Setup)
```bash
# No -k needed, uses SSH key auth
ansible-playbook playbooks/site.yml \
  -i inventory/sample_inventory.yml

# Or specific groups
ansible-playbook playbooks/docker-hosts.yml \
  -i inventory/sample_inventory.yml
```

## ✅ Verification Commands

```bash
# Check ansible user exists
ansible all -a "id ansible"

# Check SSH is hardened
ansible all -a "sudo sshd -T | grep passwordauth"
# Should show: passwordauthentication no

# Check tomek has SSH key
ansible all -a "cat ~/.ssh/authorized_keys"

# Check all users
ansible all -a "getent passwd | grep -E 'ansible|tomek'"

# Check services running (if deployed)
ansible all -a "systemctl status ssh"
```

## ❌ Troubleshooting Quick Fixes

### Can't Connect to VM
```bash
# Check VM is reachable
ping 192.168.X.X

# Check SSH is running
ssh -v tomek@192.168.X.X
# If fails: sudo systemctl start ssh (on VM)
```

### setup.yml Says "No hosts matched"
```bash
# Verify inventory file
ansible-inventory -i inventory/sample_inventory.yml --list

# Check YAML syntax
cat inventory/sample_inventory.yml | python -m yaml
```

### setup.yml Fails With Permission Error
```bash
# Make sure tomek has sudo access (default on fresh Ubuntu)
# Run again with --ask-become-pass flag
```

### Can't SSH After Setup
```bash
# Verify your SSH key is correct
cat ~/.ssh/id_ed25519.pub

# Check it matches what's in group_vars/users.yml
grep "ssh-ed25519\|ssh-rsa" group_vars/users.yml

# If different, update group_vars/users.yml and re-run setup
```

## 📊 Timeline

| Step | Time | Action |
|------|------|--------|
| 1 | 5 min | Edit config files |
| 2 | 2-3 min | Run setup.yml |
| 3 | 1 min | Verify with ping |
| 4 | 5-10 min | Run site.yml |
| **Total** | **~20 min** | **Fresh VM → Production Ready** |

## 🔒 Security Checklist

- ✅ SSH public key used (not password)
- ✅ Password auth disabled after setup
- ✅ Root login disabled
- ✅ Ansible user has no password (sudo only)
- ✅ SSH keys properly protected (600 permissions)
- ✅ Vault file encrypted (if using sensitive data)

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [SETUP_GUIDE.md](../SETUP_GUIDE.md) | Detailed setup walkthrough |
| [docs/WORKFLOW.md](WORKFLOW.md) | Architecture & flowchart |
| [docs/QUICK_SETUP.sh](QUICK_SETUP.sh) | Command reference |
| [docs/PRE_FLIGHT_CHECKLIST.md](PRE_FLIGHT_CHECKLIST.md) | Verification checklist |
| [inventory/README.md](../inventory/README.md) | Inventory documentation |

## 🎯 Success Indicators

### After setup.yml:
```
✓ "VM SETUP COMPLETE" message shown
✓ No errors in output
✓ ansible-all -m ping returns "pong"
```

### After site.yml:
```
✓ "ok" or "changed" for most tasks
✓ No "FAILED" tasks
✓ Services start successfully
✓ Playbook completes cleanly
```

## 🆘 Need Help?

1. Check [SETUP_GUIDE.md](../SETUP_GUIDE.md) troubleshooting section
2. Review [docs/WORKFLOW.md](WORKFLOW.md) flowcharts
3. Run playbook with `-vvv` for verbose output
4. Check VM has network connectivity
5. Verify SSH key is in correct format

## 🎉 You're Done When:

✅ setup.yml runs without errors
✅ All hosts respond to `ansible all -m ping`
✅ site.yml completes without FAILED tasks
✅ SSH works without passwords
✅ ansible user has passwordless sudo

**Congratulations! You have a production-ready server! 🚀**

