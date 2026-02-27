# Logging Toggles Reference

Per-component logging toggles for the Hadoop ecosystem. Components not in use default to **OFF** to avoid log noise. Enable by setting the corresponding system property when starting the daemon.

## Unified Log Directory (LOG_DIR)

All logs go to the **same directory** via the `LOG_DIR` environment variable. Default: `/logs`. Set in docker-compose or `*-env.sh` for each service. In production, Azure Monitor or similar agents can collect from this single path.

## Toggle Reference

| Component | System Property | Default | Enable With | Daemon |
|-----------|-----------------|---------|-------------|--------|
| MapReduce JobHistory audit | `mapreduce.hs.audit.logger` | OFF | `-Dmapreduce.hs.audit.logger=INFO` | JobHistoryServer |
| MapReduce Shuffle audit | `mapreduce.shuffle.audit.logger` | OFF | `-Dmapreduce.shuffle.audit.logger=INFO` | NodeManager |
| YARN Router audit | `router.audit.logger` | OFF | `-Drouter.audit.logger=INFO` | Router |
| NodeManager audit | `nm.audit.logger` | OFF | `-Dnm.audit.logger=INFO` | NodeManager |
| NameNode metrics | `namenode.metrics.logger` | OFF | `-Dnamenode.metrics.logger=INFO` | NameNode |
| DataNode metrics | `datanode.metrics.logger` | OFF | `-Ddatanode.metrics.logger=INFO` | DataNode |
| HDFS audit | (always on) | INFO | (in hdfs-env.sh) | NameNode |
| YARN RM audit | (always on) | INFO | (in yarn-env.sh) | ResourceManager |
| KMS | N/A | — | Run KMS service; uses kms-log4j2.properties | KMS |
| HTTPFS | N/A | — | Run HTTPFS service; uses httpfs-log4j2.properties | HTTPFS |

## Enabling MapReduce Audit

Add to `hadoop-conf/mapred-env.sh`:

```bash
export MAPRED_HISTORYSERVER_OPTS="${MAPRED_HISTORYSERVER_OPTS:-} -Dmapreduce.hs.audit.logger=INFO"
```

Or set in docker-compose for the jobhistoryserver service:

```yaml
environment:
  MAPRED_HISTORYSERVER_OPTS: "-Dmapreduce.hs.audit.logger=INFO -Dcom.sun.management.jmxremote=..."
```

## Log File Locations (under LOG_DIR)

| File | Component |
|------|------------|
| `hadoop.log` | General Hadoop daemon logs |
| `hdfs-audit-<hostname>.log` | HDFS operations audit |
| `rm-audit.log` | YARN ResourceManager audit |
| `spark-audit.log` | Spark driver/application audit |
| `hs-audit.log` | MapReduce JobHistory audit (when enabled) |
| `jetty-*.log` | UI access logs (namenode, datanode, resourcemanager, jobhistory, nodemanager) |
| `jetty-access.log` | Spark History Server and driver UI access |
