# Ansible Role and Module for Hadoop Logging

This document describes the Ansible role and custom module for deploying and configuring Hadoop ecosystem logging (HDFS, YARN, MapReduce, Spark).

## Overview

| Component | Purpose |
|-----------|---------|
| `ansible/roles/hadoop_logging` | Role: deploy configs, create log dirs, apply toggles |
| `ansible/playbooks/deploy-logging.yml` | Example playbook |
| `ansible/library/hadoop_logging_toggle.py` | Custom module: granular toggle control |

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `log_dir` | `/logs` | Unified log directory (LOG_DIR) |
| `hadoop_logging_deploy_path` | `{{ playbook_dir }}/../../` | Where configs are deployed on target |
| `hadoop_logging_config_source` | `{{ playbook_dir }}/../../` | Path to source configs (control node) |
| `hadoop_logging_copy_configs` | `true` | Copy hadoop-conf, spark-conf from source |
| `hadoop_logging_mapreduce_hs_audit` | `OFF` | MapReduce JobHistory audit (INFO to enable) |
| `hadoop_logging_mapreduce_shuffle_audit` | `OFF` | MapReduce Shuffle audit |
| `hadoop_logging_router_audit` | `OFF` | YARN Router audit |
| `hadoop_logging_nm_audit` | `OFF` | NodeManager audit |
| `hadoop_logging_namenode_metrics` | `OFF` | NameNode metrics |
| `hadoop_logging_datanode_metrics` | `OFF` | DataNode metrics |
| `hadoop_logging_syslog_enabled` | `false` | Use syslog config variants |
| `syslog_host` | `localhost` | Syslog server host |
| `syslog_port` | `514` | Syslog port |
| `syslog_facility` | `LOCAL1` | Syslog facility |
| `hadoop_logging_docker_deploy` | `false` | Enable Docker restart handlers |

## Usage

### Local Deployment (project root)

Deploy to the current project (e.g. after cloning or extracting the bundle):

```bash
ansible-playbook -i localhost, -c local ansible/playbooks/deploy-logging.yml
```

### Remote Deployment

Deploy to a remote host. Ensure the bundle is extracted at the target path first:

```bash
ansible-playbook -i inventory.yml ansible/playbooks/deploy-logging.yml \
  -e hadoop_logging_deploy_path=/opt/spark-hadoop-config \
  -e hadoop_logging_config_source=/path/to/bundle/extracted
```

### Enable MapReduce Audit

```bash
ansible-playbook ... -e hadoop_logging_mapreduce_hs_audit=INFO
```

### Enable Syslog

```bash
ansible-playbook ... \
  -e hadoop_logging_syslog_enabled=true \
  -e hadoop_logging_docker_deploy=true \
  -e syslog_host=logserver.example.com \
  -e syslog_port=514
```

When syslog is enabled and `hadoop_logging_docker_deploy` is true, the role creates `docker-compose.syslog.yml`. Use it with:

```bash
docker compose -f docker-compose.yml -f docker-compose.syslog.yml up -d
```

### Skip Config Copy (configs already present)

When configs are already at the deploy path (e.g. after extracting the bundle):

```bash
ansible-playbook ... -e hadoop_logging_copy_configs=false
```

## Custom Module: hadoop_logging_toggle

For granular toggle control without running the full role:

```yaml
- name: Enable MapReduce JobHistory audit
  hadoop_logging_toggle:
    component: mapreduce_hs_audit
    value: INFO
    config_path: /opt/spark-hadoop-config/hadoop-conf

- name: Disable NodeManager audit
  hadoop_logging_toggle:
    component: nm_audit
    value: OFF
```

**Supported components:** `mapreduce_hs_audit`, `mapreduce_shuffle_audit`, `router_audit`, `nm_audit`, `namenode_metrics`, `datanode_metrics`, `hive`, `hbase`, `pig`. Hive, HBase, and Pig are placeholders (not yet implemented).

## Workflow with Bundle

1. Create bundle: `./scripts/bundle-config.sh`
2. Copy `spark-hadoop-config-*.tar.gz` to target host
3. Extract: `tar -xzf spark-hadoop-config-*.tar.gz && cd spark-hadoop-config-*`
4. Run fetch-hadoop-conf: `./scripts/fetch-hadoop-conf.sh`
5. Run Ansible playbook to apply toggles and syslog (optional)
6. Start cluster: `chmod 777 logs && docker compose up -d`

## Related Documentation

- [LOGGING_TOGGLES.md](LOGGING_TOGGLES.md) — Toggle reference
- [SYSLOG_SETUP.md](SYSLOG_SETUP.md) — Syslog configuration
- [CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) — Config overview
