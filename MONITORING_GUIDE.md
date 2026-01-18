# Monitoring Stack Implementation Guide

## Overview

The Monitoring layer adds comprehensive logging, metrics collection, and alerting capabilities:
- **Loki**: Log aggregation and storage
- **Grafana Agent**: Log shipping and metrics collection
- **Prometheus**: Metrics storage and querying
- **Alertmanager**: Alert routing and notifications
- **Log Rotation**: Automatic log management
- **Monit**: Service monitoring and auto-restart

## Architecture

```
Monitoring Layer (22 total roles)
├── Essentials (9)
│   ├── APT, Packages, Users, SSH
│   ├── Timezone, Hostname, Firewall, Mail
│   └── Updates
├── Apps & Services (2)
│   ├── Docker
│   └── Rundeck
├── Security (4)
│   ├── AppArmor, OSSEC, Maldet, Lynis
├── Monitoring (7) ⭐ NEW
│   ├── Log Rotation - Manages log files
│   ├── Loki - Log aggregation
│   ├── Prometheus - Metrics storage
│   ├── Grafana Agent - Log/metrics collection
│   ├── Alertmanager - Alert routing
│   └── Monit - Service monitoring
```

## Monitoring Roles Details

### 1. Log Rotation Role

**Purpose**: Prevent log files from consuming excessive disk space

**Key Features**:
- Installs and configures logrotate
- Automatic daily log rotation
- Configurable retention (default: 30 days)
- Compressed archive support
- Automatic cleanup of old logs

**Key Variables**:
```yaml
log_rotation_retention_days: 30       # Keep 30 days of logs
log_rotation_max_age_days: 60         # Delete logs older than 60 days
log_rotation_max_size: 100M           # Rotate when log reaches 100MB
log_rotation_cron_hour: 3             # Run at 3 AM
log_rotation_compress: true           # Compress rotated logs
```

**Verification**:
```bash
ls -lah /var/log/*.gz                 # View compressed logs
logrotate -d /etc/logrotate.conf      # Test configuration
```

---

### 2. Loki Role

**Purpose**: Centralized log aggregation and storage

**Key Features**:
- Installs Loki from official releases
- Filesystem-based storage (easy setup)
- Log ingestion via push API
- Configurable retention periods
- Multi-tenancy support

**Key Variables**:
```yaml
loki_version: 2.9.0
loki_retention_days: 30               # Log retention
loki_http_port: 3100                  # HTTP API port
loki_chunk_idle_period: 15m           # Flush chunks after 15min
loki_max_chunk_age: 1h                # Max chunk age
```

**Deployment**:
```bash
ansible-playbook playbooks/site.yml --tags=loki
```

**Verification**:
```bash
curl http://localhost:3100/loki/api/v1/status/buildinfo
curl http://localhost:3100/api/prom/ready
```

**Access**:
- API Endpoint: `http://localhost:3100`
- Push Logs: `POST /loki/api/v1/push`

---

### 3. Prometheus Role

**Purpose**: Store and query metrics from your infrastructure

**Key Features**:
- Installs Prometheus from official releases
- Time-series database for metrics
- Scrape-based metrics collection
- Alert rules support
- Built-in HTTP API for queries

**Key Variables**:
```yaml
prometheus_version: 2.48.0
prometheus_port: 9090                 # Web UI port
prometheus_scrape_interval: 15s       # Collect metrics every 15s
prometheus_retention_time: 30d        # Keep 30 days of data
prometheus_enable_local_node_exporter: true
```

**Deployment**:
```bash
ansible-playbook playbooks/site.yml --tags=prometheus
```

**Verification**:
```bash
curl http://localhost:9090/api/v1/status/config
curl http://localhost:9090/-/healthy
```

**Access**:
- Web UI: `http://localhost:9090`
- Query API: `http://localhost:9090/api/v1/query`
- Alertmanager: `http://localhost:9090/config#alerting`

**Alert Rules**:
```yaml
# /etc/prometheus/alert.rules.yml
- alert: HighCPUUsage
  expr: node_cpu_seconds_total > 0.8
  for: 5m
```

---

### 4. Grafana Agent Role

**Purpose**: Collect and ship logs and metrics to Loki/Prometheus

**Key Features**:
- Single agent for logs and metrics
- Automatic log file discovery
- System metrics collection (CPU, memory, disk)
- Configurable scrape intervals
- Minimal resource overhead

**Key Variables**:
```yaml
loki_push_url: "http://localhost:3100/loki/api/v1/push"
prometheus_push_url: "http://localhost:9090/api/v1/write"
grafana_agent_scrape_interval: 15s
grafana_agent_collect_node_metrics: true
grafana_agent_collect_docker_metrics: false
```

**Deployment**:
```bash
ansible-playbook playbooks/site.yml --tags=grafana-agent
```

**Verification**:
```bash
systemctl status grafana-agent
ps aux | grep agent
curl -s http://localhost:12345/stats | jq .
```

**Collected Metrics**:
- CPU usage and context switches
- Memory usage (free, used, total)
- Disk usage and I/O
- Network interfaces statistics
- System load average

**Collected Logs**:
- System logs: `/var/log/syslog`, `/var/log/auth.log`
- Application logs: `/var/log/**/*.log`
- Custom logs: Configurable via `log_paths`

---

### 5. Alertmanager Role

**Purpose**: Route alerts and send notifications

**Key Features**:
- Alert routing based on labels
- Email notifications
- Slack integration support
- Alert grouping and throttling
- Inhibition rules for alert suppression

**Key Variables**:
```yaml
alertmanager_version: 0.26.0
alertmanager_port: 9093
alertmanager_log_level: info

# Email configuration
alertmanager_email_enabled: false
alertmanager_email_from: "alertmanager@example.com"
alertmanager_email_to: "admin@example.com"
alertmanager_smtp_host: "localhost"

# Slack configuration
alertmanager_slack_enabled: false
alertmanager_slack_webhook: "https://hooks.slack.com/..."
alertmanager_slack_channel: "#alerts"
```

**Deployment**:
```bash
ansible-playbook playbooks/site.yml --tags=alertmanager
```

**Verification**:
```bash
curl http://localhost:9093/api/v1/status
curl http://localhost:9093/api/v1/alerts
```

**Access**:
- Web UI: `http://localhost:9093`
- API: `http://localhost:9093/api/v1`

**Enable Email Alerts**:
```bash
ansible-playbook playbooks/site.yml --tags=alertmanager \
  -e alertmanager_email_enabled=true \
  -e alertmanager_email_to="ops@example.com"
```

---

### 6. Monit Role

**Purpose**: Monitor services and automatically restart them if they fail

**Key Features**:
- Service health monitoring
- Automatic service restart on failure
- System resource monitoring
- Web-based dashboard
- Email alerts
- Filesystem usage tracking

**Key Variables**:
```yaml
monit_log_level: info
monit_check_interval: 60              # Check every 60 seconds
monit_web_port: 2812                 # Web dashboard port

# Thresholds
monit_load_threshold_1min: 4.0
monit_load_threshold_5min: 3.0
monit_memory_threshold: 80

# Services to monitor (example)
monit_monitored_processes:
  - name: nginx
    pidfile: /var/run/nginx.pid
    start_cmd: /bin/systemctl start nginx
    stop_cmd: /bin/systemctl stop nginx
```

**Deployment**:
```bash
ansible-playbook playbooks/site.yml --tags=monit
```

**Verification**:
```bash
monit status                          # View all monitored services
monit summary                         # Quick summary
```

**Access**:
- Web Dashboard: `http://localhost:2812`
- Default: No authentication (configure if needed)

**Monitor Custom Services**:
```yaml
monit_monitored_processes:
  - name: api-server
    pidfile: /var/run/api.pid
    start_cmd: /usr/bin/api-server
    stop_cmd: /usr/bin/killall api-server
```

**System Monitoring**:
- CPU usage (user/system)
- Memory usage
- Swap usage
- Load average
- Disk space
- Inode usage

---

## Deployment Scenarios

### Scenario 1: Full Monitoring Stack

```bash
# Deploy all monitoring roles
ansible-playbook playbooks/monitoring-full.yml

# Or include in full stack
ansible-playbook playbooks/site.yml
```

### Scenario 2: Logs Only

```bash
ansible-playbook playbooks/site.yml --tags="log-rotation,loki,grafana-agent"
```

### Scenario 3: Metrics & Alerting Only

```bash
ansible-playbook playbooks/site.yml --tags="prometheus,alertmanager"
```

### Scenario 4: Service Monitoring Only

```bash
ansible-playbook playbooks/site.yml --tags="monit"
```

---

## Data Flow

```
Applications
    ↓
System Logs ← Grafana Agent → Loki (storage)
    ↓
Prometheus ← Grafana Agent (metrics)
    ↓
Alertmanager (evaluates rules) → Email/Slack
    ↓
Monit (watches services) → Auto-restart
```

---

## Integration with Other Roles

### Mail Integration

Enable email notifications via the mail role:

```yaml
# group_vars/all.yml
mail_enabled: true
mail_relay_host: "mail.example.com"

# Then enable in monitoring roles
alertmanager_email_enabled: true
monit_alert_enabled: true
```

### Security Integration

Combine with security roles for complete observability:

```bash
# Deploy security + monitoring
ansible-playbook playbooks/site.yml --tags="security,monitoring"
```

---

## Monitoring Stack Schedule

After deployment, the monitoring stack runs continuously:

```
Real-time:
  • Grafana Agent: Continuously ships logs and metrics
  • Monit: Checks services every 60 seconds
  • Prometheus: Scrapes metrics every 15 seconds

Scheduled:
  • Log Rotation: Daily at 3:00 AM
  • Alertmanager: Evaluates rules every 30 seconds
```

---

## Storage & Retention

### Loki Log Storage
- Location: `/var/lib/loki/`
- Retention: 30 days (configurable)
- Format: Compressed chunks

### Prometheus Metrics Storage
- Location: `/var/lib/prometheus/`
- Retention: 30 days (configurable)
- Format: Time-series database

### Log Files
- Location: `/var/log/`
- Rotation: Daily
- Compression: gzip
- Retention: 30 days + compressed archives for 60 days

---

## Querying Data

### Prometheus Queries

```promql
# CPU Usage
node_cpu_seconds_total

# Memory Usage
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes

# Disk Usage
node_filesystem_avail_bytes / node_filesystem_size_bytes

# Custom Query
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Loki Queries

```logql
# All logs
{job="syslog"}

# Filter by level
{job="syslog"} | level="error"

# Pattern matching
{job="syslog"} |= "connection refused"

# Stats
{job="syslog"} | stats count() by severity
```

---

## Troubleshooting

### Loki not receiving logs

```bash
# Check Loki is running
systemctl status loki

# Check Grafana Agent configuration
cat /etc/agent/agent.yml

# Test push
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{...}'
```

### Prometheus not scraping metrics

```bash
# Check Prometheus configuration
curl http://localhost:9090/api/v1/status/config

# View targets
curl http://localhost:9090/api/v1/targets

# Check scrape logs
tail -f /var/log/prometheus/*
```

### Alertmanager not sending alerts

```bash
# Check configuration
curl http://localhost:9093/api/v1/status

# View active alerts
curl http://localhost:9093/api/v1/alerts

# Test email
mail -s "Test" admin@example.com
```

### Monit not restarting services

```bash
# Check Monit status
monit status

# Verify syntax
monit -t

# View logs
tail -f /var/log/monit.log

# Manually restart
monit restart <service_name>
```

---

## Best Practices

### 1. Disk Space Management
```yaml
# Keep logs manageable
log_rotation_retention_days: 30
log_rotation_max_size: 100M
loki_retention_days: 30
prometheus_retention_time: 30d
```

### 2. Alert Routing
```yaml
# Route critical alerts differently
route:
  routes:
    - match:
        severity: critical
      receiver: 'critical'
      repeat_interval: 1h
```

### 3. Service Monitoring
```yaml
# Monitor critical services
monit_monitored_processes:
  - name: sshd
  - name: docker
  - name: critical-app
```

### 4. Resource Optimization
```yaml
# Adjust scrape intervals for resource constraints
grafana_agent_scrape_interval: 30s    # Less frequent collection
prometheus_retention_time: 15d        # Shorter retention
```

---

## Next Steps

1. **Deploy monitoring stack**: `ansible-playbook playbooks/monitoring-full.yml`
2. **Review web dashboards**: Prometheus, Alertmanager, Monit UIs
3. **Configure notifications**: Email/Slack for alerts
4. **Monitor critical services**: Add to Monit configuration
5. **Create custom alerts**: Add rules to Prometheus
6. **Integrate with external systems**: SIEM, dashboards (Grafana, etc.)

---

## References

- [Loki Documentation](https://grafana.com/docs/loki/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Agent](https://grafana.com/docs/agent/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Monit Documentation](https://mmonit.com/monit/)
