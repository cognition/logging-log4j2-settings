## Configuration Guide

This guide describes the key configuration files and variables that control logging behaviour.

---

## Directory Layout

- `hadoop-conf/` — Hadoop daemon configuration and logging (HDFS, YARN, MapReduce)
- `spark-conf/` — Spark daemon and client logging
- `hive-conf/` — Hive logging
- `logs/` — Unified log directory root (all logs under this tree)
- `scripts/` — Helper scripts (fetch config, test Spark on YARN, bundle configs, sync logs)
- `ansible/` — Role and playbook for deploying configs to targets
- `azure/` — Azure Monitor DCR and KQL queries
- `docs/` — Documentation

---

## Key Environment Variables

### Log Directory

- `LOG_DIR` — Directory where daemons write log files.
  - In Docker: `/logs` (mounted from `./logs`).
  - On VM: set to a path such as `/var/log/hadoop-logging`.

### Log Tags

See `LOG_TAGS.md` for details.

- `LOG_TAG_HOSTNAME` — Override hostname in log prefixes.
- `LOG_TAG_APPLICATION` — Application or deployment name.
- `LOG_TAG_ACTION` — Action/category (e.g. `[audit]`, `[access]`).
- `LOG_TAG_SECURITY` — Security context.
- `LOG_TAG_CUSTOM` — Freeform tag.

### Syslog

- `SYSLOG_HOST` — Syslog host (e.g. `localhost`, `syslog.example.com`).
- `SYSLOG_PORT` — Syslog port (default `514`).
- `SYSLOG_PROTOCOL` — `UDP` or `TCP`.
- `SYSLOG_FACILITY` — e.g. `LOCAL1`.

These are used in:

- `hadoop-conf/log4j2-syslog.properties`
- `spark-conf/log4j2-syslog.properties`
- `docker-compose.syslog.yml`
- `ansible/roles/hadoop_logging/defaults/main.yml`

---

## Hadoop Logging Configs

### `hadoop-conf/hadoop-env.sh`

- Sets `LOG_DIR` and `HADOOP_LOG_DIR`.
- Sets `HADOOP_OPTS` with `-Dlog4j.hostname` (using `LOG_TAG_HOSTNAME` if set).
- Sets `HADOOP_DAEMON_ROOT_LOGGER=INFO,RFA` so daemons log to file by default.

### `hadoop-conf/hdfs-env.sh`

- Enables HDFS audit logging (`HDFS_AUDIT_LOGGER=INFO,RFAAUDIT`).
- Sets `HDFS_NAMENODE_OPTS` and `HDFS_DATANODE_OPTS` for:
  - File-based logging
  - Metrics loggers (NameNode/DataNode)
  - JMX remote management

### `hadoop-conf/yarn-env.sh`

- `YARN_ROOT_LOGGER=INFO,RFA` for YARN daemons.
- `YARN_RESOURCEMANAGER_OPTS`:
  - File logging
  - `rm.audit.logger=INFO,RMAUDIT`
  - JMX enabled
- `YARN_NODEMANAGER_OPTS`:
  - File logging
  - `nm.audit.logger=INFO`
  - `mapreduce.shuffle.audit.logger=INFO`
  - JMX enabled

### `hadoop-conf/mapred-env.sh`

- `MAPRED_HISTORYSERVER_OPTS`:
  - File logging
  - `mapreduce.hs.audit.logger=INFO`
  - JMX enabled

### `hadoop-conf/log4j2.properties`

- Root logger:

```properties
rootLogger.level = info
rootLogger.appenderRef.console.ref = CONSOLE
rootLogger.appenderRef.RFA.ref = RFA
```

- Patterns include tags:

```properties
[${sys:log4j.hostname:-unknown}]${env:LOG_TAG_APPLICATION:-}${env:LOG_TAG_ACTION:-}${env:LOG_TAG_SECURITY:-}${env:LOG_TAG_CUSTOM:-}
```

- Dedicated appenders and loggers for:
  - HDFS audit (`hdfs-audit-<hostname>.log`)
  - RM audit (`rm-audit.log`)
  - NM audit (`nm-audit.log`)
  - JobHistory audit (`hs-audit.log`)
  - Jetty access logs (`jetty-*.log`)

### `hadoop-conf/log4j2-syslog.properties`

- Extends the above with a `SYSLOG` appender.
- Key audit and access loggers send to both file and syslog.

---

## Spark Logging Configs

### `spark-conf/log4j2.properties`

- Console appender with tag-aware pattern.
- `AUDIT` rolling file appender (`spark-audit.log`).
- `ACCESS` rolling file appender (`jetty-access.log`).
- `logger.audit` for `org.apache.spark` sends to both console and `AUDIT`.
- `logger.access` for Jetty request log sends to `ACCESS`.

### `spark-conf/log4j2-syslog.properties`

- Adds a `SYSLOG` appender and routes audit/access logs to both file and syslog.

---

## Hive Logging Configs

### `hive-conf/log4j2.properties`

- Console, `HIVEAPP` (application), and `HIVEAUDIT` (audit) appenders.
- Loggers:
  - `org.apache.hive` → `HIVEAPP`
  - `org.apache.hadoop.hive.ql.audit` → `HIVEAUDIT`

---

## Ansible Role

See `docs/ANSIBLE.md` for details. In summary:

- `ansible/roles/hadoop_logging/defaults/main.yml` — default variables.
- `ansible/roles/hadoop_logging/tasks/main.yml` — copies configs and optionally generates `docker-compose.syslog.yml`.

