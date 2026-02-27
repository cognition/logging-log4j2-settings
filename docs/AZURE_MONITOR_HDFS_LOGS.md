## Azure Monitor: Ingesting Hadoop Logs

This project is designed so that logs under `logs/` can be ingested into Azure Monitor / Log Analytics.

---

## Log Sources

1. **Host logs** — all daemon, audit, and access logs under `logs/`:
   - `logs/namenode/hadoop.log`
   - `logs/namenode/hdfs-audit-*.log`
   - `logs/resourcemanager/rm-audit.log`
   - `logs/jobhistoryserver/hs-audit.log`
   - `logs/hadoopnode/nm-audit.log`
   - `logs/spark-client/spark-audit.log`
   - `logs/hive/hive-audit.log`
   - `logs/*/jetty-*.log`
2. **YARN container logs** — aggregated container/task logs written to:
   - `logs/hdfs-container-logs/yarn-container-logs.log`

---

## Data Collection Rule (DCR)

The `azure/dcr-hdfs-logs.json` file (or equivalent ARM template) should:

- Collect lines from the `logs/` directory tree.
- Map them into one or more custom tables, e.g.:
  - `HadoopLogs_CL` for daemon/audit/access logs.
  - `HDFSYarnContainerLogs_CL` for container/task logs.

Fields to include:

- `TimeGenerated`
- `RawData` (the full log line)
- `FilePath`
- `Computer`

---

## KQL Queries

See `azure/queries/` for example Kusto Query Language (KQL) queries:

- `audit-logs.kql` — HDFS/YARN/Hive audit logs.
- `access-logs.kql` — HTTP access logs.
- `operational-queries.kql` — health and operational queries.
- `incident-detection.kql` — failures, OOM, permission denied.
- `hdfs-container-logs.kql` — container/task logs from `HDFSYarnContainerLogs_CL`.

Example: list recent HDFS audit events (host logs):

```kql
HadoopLogs_CL
| where TimeGenerated > ago(24h)
| where FilePath contains "hdfs-audit"
| project TimeGenerated, Computer, RawData
| order by TimeGenerated desc
```

Example: search container logs for exceptions:

```kql
HDFSYarnContainerLogs_CL
| where TimeGenerated > ago(24h)
| where RawData contains "Exception" or RawData contains "Error"
| project TimeGenerated, RawData
| order by TimeGenerated desc
```

