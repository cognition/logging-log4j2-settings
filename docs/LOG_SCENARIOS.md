## Log Scenarios — What Happens and What You See

This document describes key scenarios, with **example log output** and **example KQL queries** for Azure Monitor / Log Analytics.

The examples assume:

- Host logs are ingested into `HadoopLogs_CL`.
- YARN container/task logs are ingested into `HDFSYarnContainerLogs_CL`.

---

### Scenario 1 — Spark Job Submission on YARN

**What happens:** A user runs `./scripts/test-spark-yarn.sh`, which submits a Spark Pi job to YARN from `spark-client`.

**Example output:**

Spark audit (driver):

```text
[spark-client][spark-hadoop][audit] 26/03/01 12:00:34 INFO SparkContext: Submitted application: Spark Pi
```

YARN RM audit:

```text
[resourcemanager][spark-hadoop][audit] 2026-03-01T12:00:34,123 INFO org.apache.hadoop.yarn.server.resourcemanager.RMAuditLogger: USER=spark IP=172.18.0.5 OPERATION=Submit Application Request TARGET=ClientRMService RESULT=SUCCESS APPID=application_1772063068489_0001
```

**KQL query (RM submissions):**

```kql
HadoopLogs_CL
| where TimeGenerated > ago(24h)
| where FilePath contains "rm-audit" and RawData contains "OPERATION=Submit Application Request"
| extend User = extract(@"USER=(\S+)", 1, RawData)
| extend AppId = extract(@"APPID=(application_\d+_\d+)", 1, RawData)
| project TimeGenerated, Computer, User, AppId, RawData
| order by TimeGenerated desc
```

---

### Scenario 2 — MapReduce Job Submission

**What happens:** A user submits a MapReduce job (e.g. wordcount).

**Example output (JobHistory audit):**

```text
[jobhistoryserver][spark-hadoop][audit] 2026-03-01T12:05:00,000 INFO org.apache.hadoop.mapreduce.v2.hs.HSAuditLogger: USER=hadoop OPERATION=JOB_SUBMITTED JOBID=job_1772063068489_0001
```

**KQL query:**

```kql
HadoopLogs_CL
| where TimeGenerated > ago(24h)
| where FilePath contains "hs-audit"
| project TimeGenerated, Computer, RawData
| order by TimeGenerated desc
```

---

### Scenario 3 — Hive Query Submission

**What happens:** A user runs a Hive query via HiveServer2.

**Example output (Hive audit):**

```text
[hiveserver2][spark-hadoop][audit] 2026-03-01T12:10:00,000 INFO org.apache.hadoop.hive.ql.audit: user=hive_user op=QUERY db=default tbl=events stmt=SELECT * FROM events LIMIT 10
```

**KQL query:**

```kql
HadoopLogs_CL
| where TimeGenerated > ago(24h)
| where FilePath contains "hive-audit"
| project TimeGenerated, Computer, RawData
| order by TimeGenerated desc
```

---

### Scenario 4 — HDFS Permission Denied

**What happens:** A user attempts to write to a path without permission.

**Example output (HDFS audit):**

```text
[namenode][spark-hadoop][audit] 2026-03-01T12:15:00,000 INFO org.apache.hadoop.hdfs.server.namenode.FSNamesystem.audit: allowed=false ugi=user1 (auth:SIMPLE) ip=/172.18.0.7 cmd=create src=/restricted/file dst=null perm=null proto=rpc
```

**KQL query:**

```kql
HadoopLogs_CL
| where TimeGenerated > ago(7d)
| where FilePath contains "hdfs-audit" and RawData contains "allowed=false"
| project TimeGenerated, Computer, RawData
| order by TimeGenerated desc
```

---

### Scenario 5 — UI Access

**What happens:** A user opens the YARN ResourceManager UI in a browser.

**Example output (Jetty access):**

```text
[resourcemanager][spark-hadoop][access] 127.0.0.1 - - [01/Mar/2026:12:20:11 +0000] "GET /cluster HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
```

**KQL query:**

```kql
HadoopLogs_CL
| where TimeGenerated > ago(24h)
| where FilePath contains "jetty-resourcemanager"
| project TimeGenerated, Computer, RawData
| order by TimeGenerated desc
```

---

### Scenario 6 — Container OOM / Task Failure

**What happens:** A YARN container (Spark executor or MapReduce task) is killed due to OutOfMemoryError.

**Example output (HDFS container logs):**

```text
2026-03-01T12:25:00+00:00 container_1772063068489_0002_01_000005 stdout F java.lang.OutOfMemoryError: Java heap space
```

**KQL query:**

```kql
HDFSYarnContainerLogs_CL
| where TimeGenerated > ago(24h)
| where RawData contains "OutOfMemoryError" or RawData contains "exit code 137"
| project TimeGenerated, RawData
| order by TimeGenerated desc
```

