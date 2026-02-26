# Hadoop Configuration — Line-by-Line Reference

Hadoop uses **Log4j 2.x** for logging and **XML** for cluster settings. Reference: [Log4j 2 Configuration](https://logging.apache.org/log4j/2.x/manual/configuration.html), [Hadoop core-default](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/core-default.html), [HDFS default](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml), [YARN default](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-common/yarn-default.xml).

---

## hadoop-conf/log4j2.properties

### Root and General Settings

| Section | Content | What It Does |
|---------|---------|--------------|
| Root | `rootLogger.level = info` | Default: INFO level |
| Root | `rootLogger.appenderRef.console.ref = console` | Output to console |
| Console | `appender.console.*` | Writes to stderr with hostname prefix |
| Env / System | `LOG_DIR` env, `hadoop.log.dir` sys prop | Log directory. `LOG_DIR` is canonical; default `$HADOOP_HOME/logs` or `/hadoop/logs` |
| System props | `-Dlog4j.hostname` | Set in hadoop-env.sh for SIEM correlation |

### Rolling File Appender (RFA)

| Section | Content | What It Does |
|---------|---------|--------------|
| RFA | `appender.RFA.type = RollingFile` | Rolling file appender: writes to `${hadoop.log.dir}/${hadoop.log.file}` |
| RFA | `appender.RFA.policies.size.size = 256MB` | Max size before rotating |
| RFA | `appender.RFA.strategy.max = 20` | Keep 20 rotated files (20 × 256MB ≈ 5GB max) |
| RFA | `appender.RFA.layout.pattern` | Format: `[hostname] ISO8601-date level logger: message` |

### Daily Rolling File Appender (DRFA)

| Section | Content | What It Does |
|---------|---------|--------------|
| DRFA | `appender.DRFA.*` | Daily rollover at midnight. Same layout as RFA |

### Security / Audit Appenders

| Section | Content | What It Does |
|---------|---------|--------------|
| RFAS | `appender.RFAS.*` | Security audit. RFAS = Rolling File Appender Security |
| RFAAUDIT | `appender.RFAAUDIT.*` | **HDFS audit** — logs all HDFS operations (create, read, delete, etc.). Writes to `hdfs-audit-${hostname}.log` |
| Logger | `logger.hdfs_audit.additivity = false` | Don't also send to root logger (avoids duplicate lines) |

### NameNode / DataNode Metrics Logging

| Section | Content | What It Does |
|---------|---------|--------------|
| NNMETRICSRFA | `appender.NNMETRICSRFA.*` | NameNode metrics. Disabled by default via `namenode.metrics.logger` |
| DNMETRICSRFA | `appender.DNMETRICSRFA.*` | DataNode metrics. Same — disabled |

### YARN ResourceManager Audit

| Section | Content | What It Does |
|---------|---------|--------------|
| RMAUDIT | `appender.RMAUDIT.*` | **ResourceManager audit** — logs application submissions, who submitted, resource requests. Writes to `rm-audit.log` |

### YARN NodeManager Audit

| Section | Content | What It Does |
|---------|---------|--------------|
| NMAUDIT | `appender.NMAUDIT.*` | NodeManager audit. Disabled by default (enable via `nm.audit.logger`) |

### UI Access Logging (HTTP Request Logs)

| Section | Content | What It Does |
|---------|---------|--------------|
| AccessNNDRFA | `appender.AccessNNDRFA.*` | NameNode UI access log → `jetty-namenode.log` |
| AccessDNDRFA | `appender.AccessDNDRFA.*` | DataNode UI → `jetty-datanode.log` |
| AccessRMDRFA | `appender.AccessRMDRFA.*` | YARN ResourceManager UI (port 8088) → `jetty-resourcemanager.log` |
| AccessJHDRFA | `appender.AccessJHDRFA.*` | Job History UI (port 19888) → `jetty-jobhistory.log` |
| AccessNMDRFA | `appender.AccessNMDRFA.*` | NodeManager UI → `jetty-nodemanager.log` |

### EWMA (Error/Warning Metrics)

| Section | Content | What It Does |
|---------|---------|--------------|
| Note | Hadoop-specific Log4j 1 appender | EWMA (Error/Warning Metrics Appender) requires log4j-1.2-api bridge for full support. Omitted in native Log4j 2 config. |

### Component-Specific Configs

| File | Purpose |
|------|---------|
| `kms-log4j2.properties` | KMS (Key Management Server) logging |
| `httpfs-log4j2.properties` | HTTPFS (HDFS over HTTP) logging |
| `yarnservice-log4j2.properties` | YARN Slider Application Master logging |

---

## hadoop-conf/core-site.xml

Core Hadoop settings. Reference: [core-default.xml](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/core-default.html).

| Line | Content | What It Does |
|------|---------|--------------|
| 4–7 | `fs.defaultFS` = `hdfs://namenode:8020` | Default filesystem. All `hdfs://` paths use this. `namenode` = Docker service hostname, `8020` = NameNode RPC port |
| 9–12 | `hadoop.tmp.dir` = `/data` | Temporary directory. Data volume is mounted at `/data` in containers |

---

## hadoop-conf/hdfs-site.xml

HDFS-specific settings. Reference: [hdfs-default.xml](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml).

| Line | Content | What It Does |
|------|---------|--------------|
| 4–7 | `dfs.replication` = `1` | Number of copies of each block. Must be 1 with a single DataNode |
| 9–12 | `dfs.namenode.rpc-address` = `namenode:8020` | NameNode RPC address. Clients and DataNodes connect here |
| 14–16 | `dfs.client.read.shortcircuit` = `true` | Allow reading from local DataNode without going through network (faster) |
| 18–20 | `dfs.domain.socket.path` = `/run/hadoop-hdfs/dn_socket` | Unix domain socket path for short-circuit reads. Shared via `dnsocket` volume between DataNode and NodeManager |

---

## hadoop-conf/yarn-site.xml

YARN cluster settings. Reference: [yarn-default.xml](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-common/yarn-default.xml).

| Line | Content | What It Does |
|------|---------|--------------|
| 4–6 | `yarn.nodemanager.aux-services` = `mapreduce_shuffle` | Auxiliary service for MapReduce/Spark shuffle. Required for Spark on YARN |
| 8–10 | `yarn.nodemanager.env-whitelist` | Environment variables passed to containers. Includes `JAVA_HOME`, `HADOOP_*`, `PATH`, etc. |
| 12–14 | `yarn.resourcemanager.hostname` = `resourcemanager` | ResourceManager hostname. Must match Docker service |
| 16–18 | `yarn.log-aggregation-enable` = `true` | Aggregate container logs to HDFS after job completes |
| 20–22 | `yarn.nodemanager.remote-app-log-dir.groupname` = `hadoop` | Group for log aggregation directory |

---

## hadoop-conf/mapred-site.xml

MapReduce and Job History settings. Reference: [mapred-default.xml](https://hadoop.apache.org/docs/current/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml).

| Line | Content | What It Does |
|------|---------|--------------|
| 4–6 | `mapreduce.framework.name` = `yarn` | Run MapReduce on YARN (not classic MapReduce) |
| 8–10 | `mapreduce.application.classpath` | Classpath for MapReduce jobs. Uses `$HADOOP_MAPRED_HOME` |
| 12–18 | `mapreduce.jobhistory.*-dir` | HDFS paths for job history (intermediate and done) |
| 20–22 | `mapreduce.jobhistory.address` = `jobhistoryserver:10020` | JobHistory server RPC address |
| 24–26 | `mapreduce.jobhistory.webapp.address` = `jobhistoryserver:19888` | Job History web UI address |
| 28–30 | `mapreduce.reduce.memory.mb` = `1536` | Memory per reduce task (MB) |

---

## hadoop-conf/hadoop-env.sh

Environment variables for **all** Hadoop daemons. Key customisations:

| Line | Content | What It Does |
|------|---------|--------------|
| 57 | `export LANG=en_US.UTF-8` | Locale for consistent log output |
| 61 | `export HADOOP_OPTS="${HADOOP_OPTS:-} -Dlog4j.hostname=$(hostname)"` | **Critical for SIEM**: Adds hostname to every log line. `log4j.hostname` is used in layout pattern |
| 192–194 | `export LOG_DIR=...`; `export HADOOP_LOG_DIR=${LOG_DIR}` | **Standardized log dir**: `LOG_DIR` is canonical. Default `$HADOOP_HOME/logs` or `/hadoop/logs` |

---

## hadoop-conf/hadoop-metrics2.properties

Hadoop metrics output. Reference: [Hadoop Metrics2](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/Metrics.html).

| Line | Content | What It Does |
|------|---------|--------------|
| 4 | `*.sink.file.class=org.apache.hadoop.metrics2.sink.FileSink` | Write metrics to files |
| 6 | `*.period=10` | Sample metrics every 10 seconds |
| 9 | `namenode.sink.file.filename=namenode-metrics.out` | NameNode metrics file |
| 13 | `datanode.sink.file.filename=datanode-metrics.out` | DataNode metrics |
| 15 | `resourcemanager.sink.file.filename=resourcemanager-metrics.out` | ResourceManager metrics |
| 17 | `nodemanager.sink.file.filename=nodemanager-metrics.out` | NodeManager metrics |
| 21 | `jobhistoryserver.sink.file.filename=jobhistoryserver-metrics.out` | JobHistory metrics |

Output goes to `hadoop.log.dir` (e.g. `/hadoop/logs/*-metrics.out`).
