## KQL Queries for Hadoop Logs

This directory contains example Kusto Query Language (KQL) queries for analysing logs ingested from this project into Azure Monitor / Log Analytics.

Tables (example):

- `HadoopLogs_CL` — Daemon, audit, and access logs from the `logs/` tree.
- `HDFSYarnContainerLogs_CL` — YARN container/task logs from `logs/hdfs-container-logs/yarn-container-logs.log`.

Files:

- `audit-logs.kql` — HDFS, YARN, Hive, and JobHistory audit logs.
- `access-logs.kql` — HTTP access logs from all UIs.
- `operational-queries.kql` — Operational dashboards.
- `incident-detection.kql` — Failure and anomaly detection.
- `hdfs-container-logs.kql` — Container/task log analysis.

