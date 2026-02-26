# Hadoop Configuration — Line-by-Line Reference

Hadoop uses **Log4j 1.x** for logging and **XML** for cluster settings. Reference: [Log4j 1.2 Manual](https://logging.apache.org/log4j/1.2/manual.html), [Hadoop core-default](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/core-default.html), [HDFS default](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml), [YARN default](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-common/yarn-default.xml).

---

## hadoop-conf/log4j.properties

### Root and General Settings

| Line | Content | What It Does |
|------|---------|--------------|
| 18 | `hadoop.root.logger=INFO,console` | Default: INFO level, output to console. Overridden by `HADOOP_ROOT_LOGGER` env var |
| 19 | `hadoop.log.dir=.` | Base directory for log files. Overridden by `HADOOP_LOG_DIR` (set to `/hadoop/logs` in docker-compose) |
| 20 | `hadoop.log.file=hadoop.log` | Default log filename |
| 23 | `log4j.rootLogger=${hadoop.root.logger}` | Root logger uses the variable above |
| 26 | `log4j.threshold=ALL` | Minimum level for any message to pass. `ALL` = no filtering |
| 29 | `log4j.appender.NullAppender=...` | Appender that discards messages (used to turn off certain logs) |

### Rolling File Appender (RFA)

| Line | Content | What It Does |
|------|---------|--------------|
| 34–35 | `hadoop.log.maxfilesize=256MB` | Max size before rotating to new file |
| 35 | `hadoop.log.maxbackupindex=20` | Keep 20 rotated files (20 × 256MB ≈ 5GB max) |
| 36–40 | `log4j.appender.RFA.*` | Rolling file appender: writes to `${hadoop.log.dir}/${hadoop.log.file}` |
| 42–44 | `log4j.appender.RFA.layout.*` | Format: `[hostname] ISO8601-date level logger: message` |
| 45 | `ConversionPattern=[${log4j.hostname:-unknown}]...` | `log4j.hostname` set in hadoop-env.sh for SIEM correlation |

### Daily Rolling File Appender (DRFA)

| Line | Content | What It Does |
|------|---------|--------------|
| 53–57 | `log4j.appender.DRFA.*` | Daily rollover at midnight. Same layout as RFA |

### Console Appender

| Line | Content | What It Does |
|------|---------|--------------|
| 72–75 | `log4j.appender.console.*` | Writes to stderr with hostname prefix |

### Security / Audit Appenders

| Line | Content | What It Does |
|------|---------|--------------|
| 87–97 | `hadoop.security.logger`, RFAS, DRFAS | Security audit. Default `NullAppender` (off). RFAS = Rolling File Appender Security |
| 118–128 | `hdfs.audit.logger=INFO,RFAAUDIT` | **HDFS audit** — logs all HDFS operations (create, read, delete, etc.). Writes to `hdfs-audit-${hostname}.log` |
| 123 | `log4j.additivity...=false` | Don't also send to root logger (avoids duplicate lines) |

### NameNode / DataNode Metrics Logging

| Line | Content | What It Does |
|------|---------|--------------|
| 134–143 | `namenode.metrics.logger=INFO,NullAppender` | NameNode metrics. `NullAppender` = disabled by default |
| 148–156 | `datanode.metrics.logger=INFO,NullAppender` | DataNode metrics. Same — disabled |

### YARN ResourceManager Audit

| Line | Content | What It Does |
|------|---------|--------------|
| 206–215 | `rm.audit.logger=INFO,RMAUDIT` | **ResourceManager audit** — logs application submissions, who submitted, resource requests. Writes to `rm-audit.log` |
| 211 | `log4j.appender.RMAUDIT.File=${hadoop.log.dir}/rm-audit.log` | Audit file path |

### YARN NodeManager Audit

| Line | Content | What It Does |
|------|---------|--------------|
| 221–230 | `nm.audit.logger=INFO,NullAppender` | NodeManager audit. `NullAppender` = disabled (enable by changing to `NMAUDIT`) |

### UI Access Logging (HTTP Request Logs)

| Line | Content | What It Does |
|------|---------|--------------|
| 254–295 | `AccessNNDRFA`, `AccessDNDRFA`, etc. | Daily rolling appenders for HTTP access to each UI. NNDRFA=NameNode, DNDRFA=DataNode, RMDRFA=ResourceManager, JHDRFA=JobHistory, NMDRFA=NodeManager |
| 256 | `log4j.appender.AccessNNDRFA.File=${hadoop.log.dir}/jetty-namenode.log` | NameNode UI access log |
| 264 | `jetty-datanode.log` | DataNode UI |
| 272 | `jetty-resourcemanager.log` | YARN ResourceManager UI (port 8088) |
| 280 | `jetty-jobhistory.log` | Job History UI (port 19888) |
| 288 | `jetty-nodemanager.log` | NodeManager UI |

### EWMA (Error/Warning Metrics)

| Line | Content | What It Does |
|------|---------|--------------|
| 307–312 | `yarn.ewma.*`, `log4j.appender.EWMA` | Tracks unique error/warning messages for YARN. Used for alerting on repeated issues |

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
| 61 | `export HADOOP_OPTS="${HADOOP_OPTS:-} -Dlog4j.hostname=$(hostname)"` | **Critical for SIEM**: Adds hostname to every log line. `log4j.hostname` is used in ConversionPattern |

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
