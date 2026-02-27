# Syslog Setup Guide

This guide explains how to enable syslog forwarding for Spark and Hadoop audit and access logs. The syslog variants send logs to a local or remote syslog server **in addition to** the standard file appenders.

## Overview

| Component | Config File | Loggers Sent to Syslog |
|-----------|-------------|------------------------|
| Spark | `spark-conf/log4j2-syslog.properties` | Audit (job submissions), UI access (Jetty) |
| Hadoop | `hadoop-conf/log4j2-syslog.properties` | HDFS audit, RM audit, UI access (NameNode, DataNode, RM, JobHistory, NodeManager) |

## Enabling Syslog

### 1. Activation

Use the syslog config instead of the default by setting `LOG4J_CONFIGURATION_FILE` or `-Dlog4j.configurationFile` **before** the JVM starts.

#### Hadoop Services

Add `-Dlog4j.configurationFile=file:/hadoop/etc/hadoop/log4j2-syslog.properties` to the appropriate `*_OPTS` environment variable for each service. Example for `docker-compose.yml`:

```yaml
namenode:
  environment:
    LOG_DIR: /logs
    HDFS_NAMENODE_OPTS: "-Dlog4j.configurationFile=file:/hadoop/etc/hadoop/log4j2-syslog.properties -Dhdfs.audit.logger=INFO,RFAAUDIT ..."
```

Repeat for `resourcemanager` (YARN_RESOURCEMANAGER_OPTS), `datanode`, `nodemanager`, `jobhistoryserver` as needed.

#### Spark Services

For **Spark History Server** (spark-history service):

```yaml
spark-history:
  environment:
    SPARK_CONF_DIR: /spark/conf
    LOG_DIR: /logs
    SPARK_DAEMON_JAVA_OPTS: "-Dlog4j.configurationFile=file:/spark/conf/log4j2-syslog.properties"
```

For **Spark Client** (spark-client, when submitting jobs):

```yaml
spark-client:
  environment:
    SPARK_CONF_DIR: /opt/spark/conf
    SPARK_SUBMIT_OPTS: "-Dlog4j.configurationFile=file:/opt/spark/conf/log4j2-syslog.properties"
```

### 2. Syslog Parameters

Configure host, port, protocol, and facility via system properties. Defaults are shown:

| Property | Default | Description |
|----------|---------|-------------|
| `syslog.host` | `localhost` | Syslog server hostname or IP |
| `syslog.port` | `514` | Syslog port (UDP/TCP) |
| `syslog.protocol` | `UDP` | `UDP` or `TCP` |
| `syslog.facility` | `LOCAL1` | Syslog facility (e.g. `LOCAL0`, `LOCAL1`, `LOCAL2`, `USER`) |

Example for a remote syslog server:

```yaml
environment:
  HDFS_NAMENODE_OPTS: "-Dlog4j.configurationFile=file:/hadoop/etc/hadoop/log4j2-syslog.properties -Dsyslog.host=logserver.example.com -Dsyslog.port=514 -Dsyslog.facility=LOCAL1 -Dhdfs.audit.logger=INFO,RFAAUDIT ..."
```

### 3. rsyslog Example (Receiver)

On the host or a dedicated log server, configure rsyslog to receive and store Hadoop/Spark logs.

**Enable UDP/TCP input** (e.g. `/etc/rsyslog.d/50-hadoop-spark.conf`):

```
# Listen for syslog on UDP 514
module(load="imudp")
input(type="imudp" port="514")

# Optional: TCP for reliability
module(load="imtcp")
input(type="imtcp" port="514")
```

**Route LOCAL1 facility to a file**:

```
# Hadoop/Spark audit and access logs (LOCAL1 facility)
local1.*    /var/log/hadoop-spark/syslog.log
```

**Create log directory and restart rsyslog**:

```bash
sudo mkdir -p /var/log/hadoop-spark
sudo chown syslog:adm /var/log/hadoop-spark
sudo systemctl restart rsyslog
```

### 4. Docker: Sending to Host Syslog

If containers run on a host with rsyslog listening on port 514, use the host's IP or `host.docker.internal` (Docker Desktop) so containers can reach it:

```yaml
environment:
  HDFS_NAMENODE_OPTS: "-Dlog4j.configurationFile=file:/hadoop/etc/hadoop/log4j2-syslog.properties -Dsyslog.host=host.docker.internal -Dsyslog.port=514 ..."
```

On Linux, ensure the host firewall allows UDP/TCP 514 from Docker networks.

## Verification

1. Set `LOG4J_CONFIGURATION_FILE` or `-Dlog4j.configurationFile` to the syslog variant.
2. Start the cluster: `docker compose up -d`
3. Run a Spark job or perform HDFS operations.
4. Check syslog for lines containing `[hostname][Audit]` or `[hostname][Access]`.

Example log line format:

```
[namenode][Audit][RFAAUDIT] 2025-02-25T12:00:00,123 INFO FSNamesystem.audit: allowed=true ...
```

## Related Documentation

- [LOGGING_TOGGLES.md](LOGGING_TOGGLES.md) — Toggle reference for audit and access loggers
- [CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) — General configuration overview
- [BRANCH_PLAN.md](BRANCH_PLAN.md) — Branch 2 (add-syslog) scope
