## Hadoop Ecosystem Logging Project

This project provides a **logging-focused Hadoop ecosystem cluster** (HDFS, YARN, MapReduce, Spark, Hive) with:

- **Unified log directory** under `logs/` at the project root
- **All audit, metrics, and access logs enabled by default**
- **Console–file parity** (everything in `docker compose logs` is also in files)
- **Optional syslog forwarding**
- **Configurable log tags** (`LOG_TAG_*`)
- **Example queries for Azure Monitor / Log Analytics**

The primary goal is to learn and demonstrate how to instrument and collect logs from the Hadoop ecosystem. Docker Compose is a **development harness**; the configuration bundle is designed to run on a **VM or physical server** with the same behaviour.

---

## Quick Start (Docker Compose)

```bash
# 1. Start the cluster
docker compose up -d

# 2. Submit a Spark job
./scripts/test-spark-yarn.sh

# 3. Inspect logs (files and docker logs should match)
ls logs/
docker compose logs namenode
```

All log files are written under `logs/`, for example:

- `logs/namenode/hadoop.log`
- `logs/resourcemanager/rm-audit.log`
- `logs/jobhistoryserver/hs-audit.log`
- `logs/spark-client/spark-audit.log`
- `logs/hive/hive-audit.log`
- `logs/hdfs-container-logs/yarn-container-logs.log` (from sync script)

---

## VM / Physical Deployment

Use the bundle script:

```bash
./scripts/bundle-config.sh
```

This creates a tarball under `dist/` containing:

- `hadoop-conf/`
- `spark-conf/`
- `scripts/`
- `env.example` (LOG_DIR, LOG_TAG_*, syslog variables)

On a VM or physical host:

```bash
tar -xzf dist/hadoop-logging-bundle-*.tar.gz -C /opt/hadoop-logging
cd /opt/hadoop-logging
cp env.example .env
edit .env   # set LOG_DIR, LOG_TAG_*, syslog, etc.
```

You can then integrate the configs with your existing Hadoop distribution (point `HADOOP_CONF_DIR`, `SPARK_CONF_DIR`, etc. at these directories) and start daemons as usual. Logging behaviour will match the Docker Compose harness.

---

## Documentation

See the `docs/` directory for detailed information:

- `PROJECT.md` — full project overview
- `CONFIGURATION_GUIDE.md` — configuration and file index
- `LOGGING_TOGGLES.md` — syslog toggles
- `LOG_TAGS.md` — log tag variables and examples
- `SYSLOG_SETUP.md` — syslog deployment patterns
- `LOG_SCENARIOS.md` — scenarios with example output and KQL
- `ANSIBLE.md` — Ansible role and playbook
- `AZURE_MONITOR_HDFS_LOGS.md` — Azure Monitor integration

