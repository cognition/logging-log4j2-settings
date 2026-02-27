# KQL Queries for Spark-Hadoop Logs in Azure Monitor

This directory contains Kusto Query Language (KQL) queries for analysing Spark and Hadoop logs ingested into Azure Monitor (Log Analytics). Each query is documented with its purpose, expected tables, and what you will see.

---

## Log Sources and Tables

| Log Type | Source | Table Name | What It Contains |
|----------|--------|------------|------------------|
| **HDFS container logs** | YARN aggregated (HDFS) | `HDFSYarnContainerLogs_CL` | stdout, stderr, syslog from Spark executors and YARN containers. Runtime failures, OOM, exceptions. |
| **Host daemon/audit/access** | `./logs` on host | Varies by DCR | See [Host log tables](#host-log-tables) below. |

### Host Log Tables

If you configure DCRs for the host-mounted `./logs` directory, table names depend on your setup:

- **Single table:** One DCR collecting all `*.log` files → use `FilePath` to filter (e.g. `HadoopLogs_CL`).
- **Separate tables:** One DCR per log type → tables like `HDFSAudit_CL`, `RMAudit_CL`, `SparkAudit_CL`, `JettyAccess_CL`.

The queries use `HadoopLogs_CL` as a placeholder for host logs. Replace with your actual table name. Queries in `audit-logs.kql`, `access-logs.kql`, `incident-detection.kql`, and `operational-queries.kql` require host log DCRs. If you only have `HDFSYarnContainerLogs_CL` (from the HDFS sync DCR), use `hdfs-container-logs.kql` and `incident-detection.kql` (HDFS container sections only).

| Log File | Typical Content | Use For |
|----------|-----------------|---------|
| `hdfs-audit-*.log` | HDFS operations: create, delete, read, list. Fields: `ugi`, `cmd`, `src`, `allowed` | Security, access patterns |
| `rm-audit.log` | YARN submissions, allocations, completions. Fields: `USER`, `OPERATION`, `APPID` | Job lifecycle, who submitted |
| `spark-audit.log` | Spark driver lifecycle, job submissions, DAG events | Spark job tracking |
| `jetty-*.log` | HTTP access to UIs (NameNode, RM, JobHistory, etc.). NCSA-style | UI access, healthchecks |
| `jetty-access.log` | Spark History Server and driver UI access | Spark UI access |
| `hadoop.log` | Daemon startup, errors, OOM | Operational health |

---

## Query Files

| File | Purpose |
|------|---------|
| [hdfs-container-logs.kql](hdfs-container-logs.kql) | HDFS YARN container logs — failures, OOM, exceptions |
| [audit-logs.kql](audit-logs.kql) | HDFS, YARN, Spark audit — who did what, when |
| [access-logs.kql](access-logs.kql) | Jetty access logs — UI access patterns |
| [incident-detection.kql](incident-detection.kql) | Alerts, failures, OOM, permission denied |
| [operational-queries.kql](operational-queries.kql) | Dashboards, counts, trends |

---

## Quick Start

1. In Azure Portal → Log Analytics workspace → **Logs**.
2. Copy a query from the `.kql` files.
3. Replace placeholder table names if needed.
4. Run the query.

---

## Log Format Reference

### HDFS Audit (`hdfs-audit-*.log`)

```
[hostname][Audit][RFAAUDIT] 2026-02-27T12:00:00,123 INFO FSNamesystem: allowed=true ugi=spark (auth:SIMPLE) ip=/172.18.0.7 cmd=create src=/user/spark/.sparkStaging/... dst=null perm=null proto=rpc
```

- **ugi** — User (spark, hdfs, mapred)
- **cmd** — create, delete, getfileinfo, listStatus, rename
- **src** / **dst** — Paths
- **allowed** — true/false (permission denied)

### YARN RM Audit (`rm-audit.log`)

```
[resourcemanager][Audit][RMAUDIT] 2026-02-27T12:00:00,123 INFO ... USER=spark IP=172.18.0.5 OPERATION=Submit Application Request TARGET=ClientRMService RESULT=SUCCESS APPID=application_1772063068489_0001
```

- **USER** — Submitting user
- **OPERATION** — Submit Application Request, AM Allocated Container, Application Finished, etc.
- **APPID** — Application ID for correlation

### Spark Audit (`spark-audit.log`)

```
[spark-client][Audit][Spark] 26/02/26 00:00:34 INFO SparkContext: Submitted application: Spark Pi
```

### Jetty Access (NCSA-style)

```
[][Access][RMDRFA] 127.0.0.1 - - [26/Feb/2026:00:00:11 +0000] "GET / HTTP/1.1" 302 0 "-" "curl/8.5.0"
```

- **IP** — Client IP
- **Request** — GET /cluster/apps, etc.
- **Status** — 200, 302, 404, 500

### HDFS Container Logs (from sync script)

```
--- [HDFS:/tmp/logs/root/logs/application_xxx/container_yyy.log] 2026-02-27T12:00:00+00:00 ---
[executor output: INFO, WARN, ERROR, stack traces, OOM messages]
```

---

## Correlation Tips

- **Application ID** (`application_*`) — Links YARN RM audit, HDFS audit (staging paths), and container logs.
- **Hostname** — In `[hostname]` prefix; use for multi-node correlation.
- **TimeGenerated** — Use for timeline analysis across tables.
