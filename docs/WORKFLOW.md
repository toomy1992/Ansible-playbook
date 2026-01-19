# Ansible Framework Workflow

## Complete Initialization Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    UBUNTU VM INSTALLATION                        │
│  • User: John (with password)                                  │
│  • SSH: Password authentication enabled                         │
│  • Root: No remote access yet                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              STEP 1: CONFIGURE BEFORE SETUP                      │
│  1. Get your SSH public key:                                    │
│     cat ~/.ssh/id_ed25519.pub                                   │
│  2. Add to: group_vars/users.yml                                │
│  3. Update: inventory/sample_inventory.yml with VM IP           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│     STEP 2: RUN SETUP.YML (FROM YOUR PERSONAL PC)              │
│  Command:                                                        │
│    ansible-playbook playbooks/setup.yml \                       │
│      -i inventory/sample_inventory.yml \                         │
│      -u John \                                                  │
│      -k \                                                        │
│      --ask-become-pass                                          │
│                                                                  │
│  Flags:                                                          │
│    -u John          → Connect as John user                    │
│    -k                → Prompt for SSH password                  │
│    --ask-become-pass → Prompt for sudo password                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    [SETUP PLAYBOOK RUNS]
                              ↓
                  ┌─────────────────────┐
                  │  Creates:            │
                  │  • ansible user      │
                  │  • operators group   │
                  │  • SSH keys          │
                  │  • sudo access       │
                  │  • SSH hardening     │
                  └─────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              VM READY FOR AUTOMATION (SETUP COMPLETE)            │
│  • User: John → SSH key-only auth                              │
│  • User: ansible → Created, passwordless sudo                   │
│  • SSH: Hardened, key-only, no passwords                        │
│  • Firewall: Basic rules applied                                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: VERIFY SETUP (OPTIONAL BUT RECOMMENDED)               │
│  Test connection:                                                │
│    ansible all -i inventory/sample_inventory.yml -m ping        │
│                                                                  │
│  Check users:                                                    │
│    ansible all -i inventory/sample_inventory.yml \              │
│      -a "id ansible"                                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│      STEP 4: DEPLOY FULL CONFIGURATION (SITE.YML)              │
│  Command:                                                        │
│    ansible-playbook playbooks/site.yml \                        │
│      -i inventory/sample_inventory.yml                          │
│                                                                  │
│  OR group-specific:                                             │
│    ansible-playbook playbooks/docker-hosts.yml \                │
│      -i inventory/sample_inventory.yml                          │
│                                                                  │
│  OR specific roles:                                             │
│    ansible-playbook playbooks/site.yml \                        │
│      -i inventory/sample_inventory.yml \                         │
│      --tags=docker,prometheus                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│            FULLY CONFIGURED PRODUCTION SERVER                    │
│  ✓ Essentials deployed (APT, Packages, Users, SSH, etc)        │
│  ✓ Security hardened (AppArmor, OSSEC, Maldet, Lynis)          │
│  ✓ Monitoring enabled (Loki, Prometheus, Alertmanager, Monit)  │
│  ✓ Apps installed (Docker and/or Rundeck as needed)            │
│  ✓ All SSH keys deployed                                       │
│  ✓ Firewall rules configured                                   │
│  ✓ Automatic updates enabled                                   │
│  ✓ Ready for production use                                    │
└─────────────────────────────────────────────────────────────────┘
```

## Setup.yml Playbook Details

```
setup.yml
├── Pre-tasks
│   ├── Display setup information
│   └── Verify sudo-capable user
│
├── Role: user_accounts
│   ├── Creates 'ansible' group (gid 1000)
│   ├── Creates 'ansible' user (uid 1000)
│   └── Enables passwordless sudo for ansible
│
├── Role: users_ops
│   ├── Creates 'operators' group (gid 1100)
│   ├── Configures 'John' user
│   ├── Adds SSH public keys to authorized_keys
│   └── Sets up sudo access
│
├── Role: ssh
│   ├── Disables password authentication
│   ├── Disables root login
│   ├── Enables key-only login
│   ├── Hardens ciphers and key exchange
│   └── Applies SSH hardening best practices
│
└── Post-tasks
    ├── Display completion message
    └── Verify ansible user works
```

## Playbook Execution Order

### First Time Setup (Fresh VM)
```
1. setup.yml
   ↓ (creates ansible user, hardens SSH)
2. site.yml (or group-specific playbook)
   ↓ (deploys all roles to configured hosts)
```

### Subsequent Deployments
```
site.yml
├── Essentials playbook
│   ├── APT
│   ├── Packages
│   ├── Users
│   ├── SSH
│   ├── Timezone
│   ├── Hostname
│   ├── Firewall
│   ├── Mail
│   └── Updates
│
├── Apps (conditional)
│   ├── Docker (on docker_hosts, ubuntu_desktop)
│   └── Rundeck (on rundeck_hosts only)
│
├── Security
│   ├── AppArmor
│   ├── Integrity Monitoring (OSSEC)
│   ├── Malware Scanning (Maldet)
│   └── Security Audits (Lynis)
│
└── Monitoring
    ├── Log Rotation
    ├── Loki
    ├── Prometheus
    ├── Grafana Agent
    ├── Alertmanager
    └── Monit
```

## Key Configuration Files

```
Ansible-playbook/
├── playbooks/
│   ├── setup.yml                ← START HERE for fresh VMs
│   ├── site.yml                 ← Main playbook (all hosts)
│   ├── common-hosts.yml         ← Essentials only
│   ├── docker-hosts.yml         ← Essentials + Docker
│   ├── rundeck-hosts.yml        ← Essentials + Rundeck
│   └── desktop-hosts.yml        ← Desktop + Docker
│
├── inventory/
│   ├── sample_inventory.yml     ← Define your hosts here
│   └── README.md                ← Inventory documentation
│
├── group_vars/
│   ├── all.yml                  ← Variables for all hosts
│   ├── users.yml                ← SSH keys and users
│   └── vault.yml                ← Encrypted credentials
│
├── SETUP_GUIDE.md               ← Detailed setup instructions
└── docs/
    └── QUICK_SETUP.sh           ← Quick reference commands
```

## Troubleshooting Flowchart

```
Fresh VM Setup Issues?
│
├─ Can't connect to VM?
│  ├─ Check VM is running and has network
│  ├─ Check SSH is enabled: sudo systemctl status ssh
│  ├─ Test: ssh -v John@192.168.X.X
│  └─ Add firewall rule: sudo ufw allow 22/tcp
│
├─ setup.yml command fails?
│  ├─ Verify you're in the right directory
│  ├─ Check inventory IP is correct
│  ├─ Verify SSH public key is in group_vars/users.yml
│  ├─ Re-run setup (it's idempotent - safe to retry)
│  └─ Use -vvv for verbose output
│
├─ setup.yml succeeds but can't connect after?
│  ├─ Check ansible user was created: ssh ansible@IP id
│  ├─ Verify SSH keys were added
│  ├─ Check SSH config: sudo sshd -T | grep password
│  └─ Re-run setup playbook
│
└─ site.yml fails after setup?
   ├─ Make sure you're using correct user (ansible)
   ├─ Verify SSH keys are still valid
   ├─ Check inventory group names match playbook expectations
   └─ Review error message and specific role that failed
```

## Multi-VM Deployment

```
For multiple VMs in sequence:

1. Install all VMs with user 'John'
2. Add all VM IPs to inventory/sample_inventory.yml
3. Add all SSH public keys to group_vars/users.yml
4. Run setup.yml against all hosts:
   ansible-playbook playbooks/setup.yml \
     -i inventory/sample_inventory.yml \
     -u John \
     -k \
     --ask-become-pass

5. Run site.yml against all (or group-specific):
   ansible-playbook playbooks/site.yml \
     -i inventory/sample_inventory.yml

This initializes all VMs in parallel!
```

## Success Indicators

### After setup.yml completes:
```
✓ ansible user created (id 1000)
✓ John has SSH key authentication
✓ Password authentication disabled
✓ SSH config hardened
✓ Firewall rules applied
✓ Ready for site.yml deployment
```

### After site.yml completes:
```
✓ All essentials deployed
✓ Security hardening applied
✓ Monitoring configured
✓ SSH keys distributed
✓ Users created and configured
✓ Services running and enabled
✓ Firewall rules active
✓ System fully configured
```

## Command Reference

### Setup Phase (Fresh VM)
```bash
# Configure before running
nano group_vars/users.yml           # Add SSH public key
nano inventory/sample_inventory.yml # Update VM IP

# Run setup
ansible-playbook playbooks/setup.yml \
  -i inventory/sample_inventory.yml \
  -u John \
  -k \
  --ask-become-pass

# Verify
ansible all -i inventory/sample_inventory.yml -m ping
```

### Deployment Phase (After Setup)
```bash
# Full deployment
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml

# Group-specific
ansible-playbook playbooks/docker-hosts.yml -i inventory/sample_inventory.yml
ansible-playbook playbooks/rundeck-hosts.yml -i inventory/sample_inventory.yml

# Specific roles
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml --tags=docker
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml --tags=prometheus

# Test run (no changes)
ansible-playbook playbooks/site.yml -i inventory/sample_inventory.yml --check
```

