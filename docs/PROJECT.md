# Spark-Hadoop Logging Project — Project Documentation

Comprehensive documentation for the Apache Spark and Hadoop logging investigation project: what it does, dependencies, how to use it, and references.

---

## What This Project Does

This project provides a **Docker Compose–based Spark-on-YARN cluster** with configurable logging for practising and demonstrating Hadoop ecosystem logging. It is designed for:

- **System administrators** learning or tuning Spark/Hadoop logging
- **SIEM integration** — unified log directory, hostname prefixes, audit and access logs
- **Deployment** — bundle configs for another system; Ansible role for automation

### Key Features

| Feature | Description |
|--------|-------------|
| **Unified logging** | All components (HDFS, YARN, MapReduce, Spark) write to a single `logs/` directory via `LOG_DIR` |
| **Audit logs** | HDFS operations, YARN application submissions, Spark job lifecycle, MapReduce JobHistory (optional) |
| **UI access logs** | HTTP request logging for all web UIs (NameNode, DataNode, RM, JobHistory, NodeManager, Spark History) |
| **Syslog variants** | Optional configs that forward audit/access logs to syslog (local or remote) |
| **Log4j 2** | Both Spark and Hadoop use Log4j 2 for consistent configuration |
| **Hostname prefix** | Every log line includes `[hostname]` for SIEM correlation |

### Components

| Component | Role |
|-----------|------|
| **NameNode / DataNode** | HDFS distributed storage |
| **ResourceManager** | YARN cluster manager (schedules jobs) |
| **NodeManager** | YARN worker (runs Spark executors) |
| **JobHistoryServer** | MapReduce job history |
| **Spark History Server** | Spark application history |
| **spark-client** | Container for submitting Spark jobs |

---

## Dependencies

### Required (Core Usage)

| Dependency | Version | Purpose |
|------------|---------|---------|
| **Docker** | 20.10+ | Run containers |
| **Docker Compose** | v2+ (Compose V2) | Orchestrate services |
| **Git** | Any | Fetch Hadoop config via `fetch-hadoop-conf.sh` |
| **Bash** | 4+ | Run scripts |

### Optional (Testing)

| Dependency | Version | Purpose |
|------------|---------|---------|
| **Python** | 3.12 (preferred; 3.6+ compatible) | Run pytest |
| **pytest** | ≥5.0 | Log verification tests |

### Optional (Deployment)

| Dependency | Version | Purpose |
|------------|---------|---------|
| **Ansible** | 2.9+ | Deploy configs, apply toggles, syslog vars |

### Container Images (Pulled Automatically)

| Image | Source |
|-------|--------|
| `ghcr.io/hadoop-sandbox/hadoop-hdfs-namenode` | hadoop-sandbox |
| `ghcr.io/hadoop-sandbox/hadoop-hdfs-datanode` | hadoop-sandbox |
| `ghcr.io/hadoop-sandbox/hadoop-yarn-resourcemanager` | hadoop-sandbox |
| `ghcr.io/hadoop-sandbox/hadoop-yarn-nodemanager-spark` | hadoop-sandbox |
| `ghcr.io/hadoop-sandbox/hadoop-mapred-jobhistoryserver` | hadoop-sandbox |
| `ghcr.io/hadoop-sandbox/spark-historyserver` | hadoop-sandbox |
| `apache/spark` | 3.5.6 |
| `busybox` | latest |

---

## How to Use It

### Quick Start (Local Development)

```bash
# 1. Fetch Hadoop config from hadoop-sandbox (run once)
./scripts/fetch-hadoop-conf.sh

# 2. Ensure logs directory is writable
chmod 777 logs

# 3. Start YARN cluster + Spark client
docker compose up -d

# 4. Wait ~3–5 min for services to be healthy
docker compose ps

# 5. Submit a Spark job
./scripts/test-spark-yarn.sh
```

### Bundle for Deployment

Create a deployable tar archive:

```bash
./scripts/bundle-config.sh
# Creates spark-hadoop-config-YYYYMMDD.tar.gz
```

On target host:

```bash
tar -xzf spark-hadoop-config-*.tar.gz && cd spark-hadoop-config-*
./scripts/fetch-hadoop-conf.sh
chmod 777 logs
docker compose up -d
```

### Run Tests

```bash
pip install -r requirements-test.txt
pytest tests/ -v
```

Requires the cluster to be running (`docker compose up -d`).

### Ansible Deployment

Apply toggles or syslog config via Ansible:

```bash
ansible-playbook -i localhost, -c local ansible/playbooks/deploy-logging.yml
```

With MapReduce audit enabled:

```bash
ansible-playbook ... -e hadoop_logging_mapreduce_hs_audit=INFO
```

See [ANSIBLE.md](ANSIBLE.md) for details.

### Enable Syslog

Use syslog config variants to forward logs to a syslog server. See [SYSLOG_SETUP.md](SYSLOG_SETUP.md).

---

## Project Layout

| Path | Purpose |
|------|---------|
| `hadoop-conf/` | Hadoop config (HDFS, YARN, MapReduce). Mounted to `/hadoop/etc/hadoop` |
| `spark-conf/` | Spark config (log4j2, spark-defaults, metrics). Mounted to `/opt/spark/conf` |
| `logs/` | Unified log directory. Mounted to `/logs` |
| `scripts/` | fetch-hadoop-conf.sh, test-spark-yarn.sh, bundle-config.sh |
| `ansible/` | Role, playbook, custom module |
| `docs/` | Documentation |
| `tests/` | Log verification tests |
| `jmx-exporter-config/` | JMX Exporter YAML configs (optional) |

---

## Documentation Index

| Document | Contents |
|----------|----------|
| [CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) | Config reference, glossary, file index |
| [LOGGING_TOGGLES.md](LOGGING_TOGGLES.md) | Per-component toggles (MapReduce, Router, NM audit, etc.) |
| [SYSLOG_SETUP.md](SYSLOG_SETUP.md) | Syslog configuration, rsyslog example |
| [LOG_SCENARIOS.md](LOG_SCENARIOS.md) | What happens and what you see in logs |
| [SCRIPTS.md](SCRIPTS.md) | Script reference |
| [ANSIBLE.md](ANSIBLE.md) | Ansible role and module |
| [SPARK_CONF.md](SPARK_CONF.md) | Line-by-line Spark config |
| [HADOOP_CONF.md](HADOOP_CONF.md) | Line-by-line Hadoop config |
| [DOCKER_COMPOSE.md](DOCKER_COMPOSE.md) | Line-by-line docker-compose |

---

## References

### Official Documentation

| Resource | URL |
|----------|-----|
| Apache Spark Configuration | https://spark.apache.org/docs/latest/configuration.html |
| Apache Hadoop Common | https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/core-default.html |
| Apache Hadoop HDFS | https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml |
| Apache Hadoop YARN | https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-common/yarn-default.xml |
| Log4j 2 Configuration | https://logging.apache.org/log4j/2.x/manual/configuration.html |
| Docker Compose File Reference | https://docs.docker.com/compose/compose-file/ |

### Upstream Projects

| Project | URL |
|---------|-----|
| hadoop-sandbox | https://github.com/hadoop-sandbox/hadoop-sandbox |
| Apache Spark | https://spark.apache.org/ |
| Apache Hadoop | https://hadoop.apache.org/ |

### Related Concepts

- **SIEM** — Security Information and Event Management — log aggregation for security
- **LOG_DIR** — Unified env var for all ecosystem logs. Default: `/logs`
- **JMX** — Java Management Extensions — monitoring/metrics interface

---

## Ports

| Port | Service |
|------|---------|
| 8088 | YARN ResourceManager UI |
| 18080 | Spark History Server |
| 19888 | MapReduce Job History UI |
| 9870 | HDFS NameNode (internal) |
| 4040 | Spark driver UI (when job runs) |

---

## Troubleshooting

**Permission denied: user=spark**

```bash
docker exec -u hdfs spark-hadoop-namenode-1 hdfs dfs -mkdir -p /user/spark /spark-history
docker exec -u hdfs spark-hadoop-namenode-1 hdfs dfs -chmod -R 777 /user /spark-history
```

**Migration from hadoop-logs/spark-logs**

Copy existing logs into `logs/` and remove the old directories.
