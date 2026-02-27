## Hadoop Ecosystem Logging Project — Overview

This project defines a **logging-first Hadoop ecosystem cluster**. It provides:

- HDFS, YARN, MapReduce, Spark, and Hive services
- A **unified log directory** (`logs/`) at the project root
- **All audit, metrics, and access logs enabled by default**
- Optional **syslog forwarding**
- **Configurable log tags** (`LOG_TAG_*`) for SIEM correlation
- Example queries for **Azure Monitor / Log Analytics**

Docker Compose is used as a **development harness**; the configuration bundle is designed so it can be deployed on a **VM or physical host** with identical logging behaviour.

---

## Components

- **HDFS** — NameNode + DataNode
- **YARN** — ResourceManager + NodeManager
- **MapReduce** — JobHistoryServer
- **Spark** — Spark History Server + client
- **Hive** — Metastore + HiveServer2
- **Log sync** — Periodically copies YARN container/task logs from HDFS to local files

---

## Logging Design

### Unified Log Directory

All components write logs to a unified directory:

- Inside containers or daemons: `LOG_DIR` (default `/logs`)
- On the host / project: `logs/` under the project root

Example layout:

- `logs/namenode/hadoop.log`
- `logs/resourcemanager/rm-audit.log`
- `logs/jobhistoryserver/hs-audit.log`
- `logs/hadoopnode/nm-audit.log`
- `logs/spark-client/spark-audit.log`
- `logs/hive/hive-audit.log`
- `logs/hdfs-container-logs/yarn-container-logs.log`

### Console–File Parity

Root loggers are configured so that:

- Every line written to console (visible in `docker compose logs`) is **also** written to a file under `logs/`.
- You can use either `docker compose logs` or `logs/` as the source for log analytics.

### Configurable Tags

Log line prefixes include:

- Hostname (overridable by `LOG_TAG_HOSTNAME`)
- Optional application, action, security, and custom tags (`LOG_TAG_APPLICATION`, `LOG_TAG_ACTION`, `LOG_TAG_SECURITY`, `LOG_TAG_CUSTOM`)

Example:

```text
[namenode][spark-hadoop][audit][school-is-fun] 2026-03-01T12:00:00,123 INFO FSNamesystem.audit: allowed=true ...
```

---

## Remote Log Forwarding

Remote log forwarding is controlled by a **single toggle**:

- Enable or disable forwarding to a syslog endpoint
- Configure host, port, protocol, and facility

When enabled, key audit and access logs are sent to syslog **in addition** to local files.

---

## VM / Physical Host Deployment

The configs are designed so they can be deployed on a VM or physical server:

1. Use `./scripts/bundle-config.sh` to create a tarball.
2. Extract on the target host.
3. Source `env.example` (or copy to `/etc/sysconfig`/systemd env).
4. Point your Hadoop and Spark daemons at `hadoop-conf/` and `spark-conf/`.

No Docker is required on the target host for logging behaviour to work.

