---
# Grafana Alloy Migration Guide

## Overview
This document outlines the transition from Grafana Agent + Promtail to Grafana Alloy, a unified observability backend.

## What Changed

### 1. ✅ Created Grafana Alloy Role
**Location:** `roles/grafana_alloy/`

A new comprehensive role has been created with:
- **defaults/main.yml**: Configuration variables for Alloy
- **tasks/main.yml**: Installation and setup tasks
- **handlers/main.yml**: Service restart handlers
- **templates/alloy-config.alloy.j2**: Complete Alloy configuration

**Key Features:**
- Installs Alloy from official Grafana repository
- Collects node metrics (CPU, memory, disk, network)
- Collects logs from syslog and auth.log files
- Pushes metrics to Prometheus
- Pushes logs to Loki
- Uses Alloy's native configuration format (.alloy files)

### 2. ✅ Updated Playbooks
**Files Modified:**
- `playbooks/monitoring-full.yml` - Replaced grafana_agent with grafana_alloy
- `playbooks/site.yml` - Replaced grafana_agent with grafana_alloy
- `playbooks/common-hosts.yml` - Replaced grafana_agent with grafana_alloy
- `playbooks/docker-hosts.yml` - Replaced grafana_agent with grafana_alloy
- `playbooks/desktop-hosts.yml` - Replaced grafana_agent with grafana_alloy

All playbooks now reference the new `grafana_alloy` role instead of `grafana_agent`.

### 3. ✅ Prepared Promtail Removal Playbook
**Location:** `playbooks/promtail-removal.yml`

This playbook cleanly removes:
- Promtail Docker container
- Promtail Docker image
- Promtail configuration directory
- Promtail-related firewall rules
- syslog-ng package and configuration

**Updated to reference Alloy in next steps**

### 4. ✅ Updated syslog-ng Integration
**Location:** `roles/syslog_ng/templates/syslog-ng.conf.j2`

The syslog-ng configuration now:
- Listens on UDP 514 and TCP 601 (unchanged)
- Logs to local file instead of forwarding to Promtail
- Includes commented-out option to forward to Promtail if needed
- Compatible with Alloy's file-based log collection

Since Alloy reads directly from log files (`/var/log/syslog`, `/var/log/auth.log`), syslog-ng forwarding becomes optional.

### 5. ✅ Updated Group Variables
**Location:** `group_vars/all.yml`

Replaced Agent variables with Alloy variables:
```yaml
# Old (Grafana Agent)
grafana_agent_version: latest
grafana_agent_scrape_interval: 15s
grafana_agent_collect_node_metrics: true

# New (Grafana Alloy)
grafana_alloy_version: latest
grafana_alloy_scrape_interval: 15s
grafana_alloy_collect_node_metrics: true
grafana_alloy_collect_syslog: true
grafana_alloy_collect_auth_logs: true
```

## Migration Workflow

### Phase 1: Deploy Alloy
```bash
# Deploy Alloy to all hosts
ansible-playbook playbooks/monitoring-full.yml --tags grafana-alloy

# Verify Alloy is running
ansible -i inventory/semaphore-server.yaml -m shell -a "systemctl status alloy"
ansible -i inventory/runtipi-server.yaml -m shell -a "systemctl status alloy"

# Check Alloy metrics endpoint
ansible -i inventory/semaphore-server.yaml -m shell -a "curl -s http://localhost:12345/api/v1/status | jq"
```

### Phase 2: Verify Data Collection
```bash
# Check Prometheus metrics from Alloy
curl http://localhost:9090/api/v1/query?query=node_cpu_seconds_total

# Check Loki logs from Alloy
curl http://localhost:3100/loki/api/v1/query?query='{}' | jq

# Monitor Alloy logs
ansible -i inventory/semaphore-server.yaml -m shell -a "journalctl -u alloy -n 50 --no-pager"
```

### Phase 3: Remove Promtail & syslog-ng
Once Alloy is verified and metrics/logs are flowing:

```bash
# Run Promtail removal playbook
ansible-playbook playbooks/promtail-removal.yml -i inventory/semaphore-server.yaml
ansible-playbook playbooks/promtail-removal.yml -i inventory/runtipi-server.yaml

# This will remove:
# - Promtail container and image
# - Promtail configuration
# - Firewall rules for Promtail ports
# - syslog-ng package and configuration
```

## Comparison: Agent vs Alloy

| Feature | Grafana Agent | Grafana Alloy |
|---------|---------------|---------------|
| **Metrics Collection** | ✅ Prometheus scraping | ✅ Enhanced scraping |
| **Log Collection** | Via Promtail side-car | ✅ Native file/syslog sources |
| **Metrics Push** | ✅ Prometheus remote_write | ✅ Prometheus remote_write |
| **Logs Push** | Via Promtail | ✅ Loki direct push |
| **Configuration Format** | YAML | ✅ Alloy (HCL-like) |
| **Performance** | Standard | ✅ Optimized |
| **Future Development** | Deprecated | ✅ Active development |
| **Component Unification** | Separate components | ✅ Single binary |

## Key Differences in Operation

### Configuration Files
- **Agent:** YAML files
- **Alloy:** Native `.alloy` files with HCL-like syntax

### Service Management
- **Agent:** `systemctl status grafana-agent`
- **Alloy:** `systemctl status alloy`

### HTTP Port
- **Agent:** Port 9091 (configurable)
- **Alloy:** Port 12345 (configurable via `grafana_alloy_http_port`)

### Log Paths
- **Agent:** Uses Promtail syslog listener on port 1514
- **Alloy:** Reads directly from `/var/log/syslog`, `/var/log/auth.log`

## Rollback Plan

If you need to revert to Grafana Agent:

```bash
# Restore Agent role from backup/previous commit
git checkout HEAD~1 roles/grafana_agent/

# Update playbooks to use grafana_agent instead of grafana_alloy
# Reinstall Agent
ansible-playbook playbooks/monitoring-full.yml --tags grafana-agent

# Redeploy Promtail if needed
ansible-playbook playbooks/monitoring-full.yml --tags promtail
```

## Troubleshooting

### Alloy not collecting metrics
```bash
# Check service status
systemctl status alloy

# View logs
journalctl -u alloy -n 100

# Verify config syntax
alloy run /etc/alloy/config.alloy --dry-run
```

### Missing logs in Loki
```bash
# Check log file permissions
ls -la /var/log/syslog /var/log/auth.log

# Verify Loki endpoint
curl -v http://localhost:3100/loki/api/v1/push

# Check Alloy config
cat /etc/alloy/config.alloy
```

### Prometheus not receiving metrics
```bash
# Check remote write endpoint
curl -I http://localhost:9090/api/v1/write

# Verify metrics in Prometheus
curl http://localhost:9090/api/v1/query?query=node_memory_MemAvailable_bytes
```

## File Structure
```
roles/grafana_alloy/
├── defaults/main.yml          # Default variables
├── handlers/main.yml          # Service handlers
├── tasks/main.yml             # Installation tasks
└── templates/
    └── alloy-config.alloy.j2  # Alloy configuration template

playbooks/
├── monitoring-full.yml        # Updated to use grafana_alloy
├── site.yml                   # Updated to use grafana_alloy
├── docker-hosts.yml          # Updated to use grafana_alloy
├── common-hosts.yml          # Updated to use grafana_alloy
├── desktop-hosts.yml         # Updated to use grafana_alloy
└── promtail-removal.yml      # Promtail cleanup playbook

roles/syslog_ng/templates/
└── syslog-ng.conf.j2         # Updated for Alloy compatibility

group_vars/
└── all.yml                    # Updated variables
```

## Next Steps

1. **Test in staging:** Run playbooks against staging hosts first
2. **Monitor carefully:** Watch metrics/logs in Grafana during migration
3. **Gradual rollout:** Deploy to hosts one at a time
4. **Validate data:** Confirm all metrics and logs are flowing
5. **Cleanup:** Remove Promtail in a separate maintenance window

## Support & Documentation
- Grafana Alloy: https://grafana.com/docs/alloy/latest/
- GitHub: https://github.com/grafana/alloy
- Migration Guide: https://grafana.com/docs/alloy/latest/get-started/migrating-from-grafana-agent/
