# Spark/Hadoop Configuration Guide for System Administrators

This guide explains **every configuration line** in this project. It is written for system administrators who support Spark and Hadoop but may not have Java development experience.

## Who This Is For

- **System administrators** who need to understand, troubleshoot, or modify Spark/Hadoop deployments
- **Operations staff** who manage logging, monitoring, and SIEM integration
- **DevOps engineers** who maintain Docker-based clusters

## Quick Reference: What Each File Does

| File | Purpose | When to Edit |
|------|---------|--------------|
| `spark-conf/log4j2.properties` | Spark logging (console, audit file, UI access) | Change log levels, add appenders |
| `spark-conf/log4j2-syslog.properties` | Spark + syslog (audit, UI access to syslog) | Use when forwarding to SIEM/syslog — see [SYSLOG_SETUP.md](SYSLOG_SETUP.md) |
| `spark-conf/spark-defaults.conf` | Spark runtime settings (master, event log, etc.) | Change cluster mode, memory, history |
| `spark-conf/metrics.properties` | Spark Prometheus metrics | Add/change metrics sinks |
| `hadoop-conf/log4j2.properties` | Hadoop logging (HDFS, YARN, audit, UI) | Change log levels, audit settings |
| `hadoop-conf/log4j2-syslog.properties` | Hadoop + syslog (HDFS/RM audit, UI access to syslog) | Use when forwarding to SIEM/syslog — see [SYSLOG_SETUP.md](SYSLOG_SETUP.md) |
| `hadoop-conf/core-site.xml` | Hadoop core settings (HDFS URI, temp dir) | Change cluster hostnames |
| `hadoop-conf/hdfs-site.xml` | HDFS-specific settings | Replication, NameNode address |
| `hadoop-conf/yarn-site.xml` | YARN cluster settings | ResourceManager host, log aggregation |
| `hadoop-conf/mapred-site.xml` | MapReduce/JobHistory settings | Job history server address |
| `hadoop-conf/hadoop-env.sh` | Environment variables for all Hadoop daemons | Log hostname, locale |
| `hadoop-conf/hadoop-metrics2.properties` | Hadoop metrics output | File/Ganglia sinks |
| `docker-compose.yml` | Container definitions and mounts | Add services, change ports |

## Documentation Index

| Document | Contents |
|----------|----------|
| [LOGGING_TOGGLES.md](LOGGING_TOGGLES.md) | **Toggles:** Per-component enable/disable; LOG_DIR; MapReduce, Router, NM audit |
| [SYSLOG_SETUP.md](SYSLOG_SETUP.md) | **Syslog:** Enable syslog variants; host/port/facility; rsyslog example |
| [LOG_SCENARIOS.md](LOG_SCENARIOS.md) | **Scenarios:** What happens and what you see in the logs (job submission, CRUD, startup, failures) |
| [SCRIPTS.md](SCRIPTS.md) | **Scripts:** fetch-hadoop-conf.sh, test-spark-yarn.sh, bundle-config.sh (deploy tar) |
| [ANSIBLE.md](ANSIBLE.md) | **Ansible:** hadoop_logging role, hadoop_logging_toggle module, deploy-logging playbook |
| [SPARK_CONF.md](SPARK_CONF.md) | Line-by-line: `log4j2.properties`, `spark-defaults.conf`, `metrics.properties` |
| [HADOOP_CONF.md](HADOOP_CONF.md) | Line-by-line: `log4j2.properties`, `core-site.xml`, `hdfs-site.xml`, `yarn-site.xml`, `mapred-site.xml`, `hadoop-env.sh`, `hadoop-metrics2.properties` |
| [DOCKER_COMPOSE.md](DOCKER_COMPOSE.md) | Line-by-line: `docker-compose.yml` |

## Official References

- **Apache Spark Configuration**: <https://spark.apache.org/docs/latest/configuration.html>
- **Apache Hadoop Common (core-site)**: <https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/core-default.html>
- **Apache Hadoop HDFS**: <https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml>
- **Apache Hadoop YARN**: <https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-common/yarn-default.xml>
- **Log4j 2.x (Spark and Hadoop)**: <https://logging.apache.org/log4j/2.x/manual/configuration.html>
- **Docker Compose**: <https://docs.docker.com/compose/compose-file/>

## Glossary (Non-Java Terms)

| Term | Meaning |
|------|---------|
| **Appender** | Where logs go (console, file, etc.) |
| **Logger** | A named category that produces log messages |
| **JVM** | Java Virtual Machine — the runtime that runs Java code |
| **Daemon** | A background service (e.g., NameNode, ResourceManager) |
| **RPC** | Remote Procedure Call — how services talk over the network |
| **LOG_DIR** | Unified env var for all ecosystem logs. Default: `/logs`. Single directory for Azure Monitor/SIEM collection. |
| **SIEM** | Security Information and Event Management — log aggregation for security |
| **JMX** | Java Management Extensions — monitoring/metrics interface |
