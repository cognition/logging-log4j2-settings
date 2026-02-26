# Log Scenarios — What Happens and What You See

This document describes **concrete scenarios**: what happens when users and systems interact with the cluster, and **exactly what log entries** appear where. Use it to correlate events with logs, troubleshoot issues, or configure SIEM rules.

---

## Scenario 1: User Submits a Spark Job (Program Initiation)

**What happens:** An administrator runs `./scripts/test-spark-yarn.sh`, which executes `spark-submit` inside the spark-client container. The Spark Pi example runs on YARN.

### Timeline and Logs

| Step | What Happens | Where to Look | Example Log Entry |
|------|--------------|---------------|-------------------|
| 1 | spark-submit starts, driver initialises | `spark-logs/spark-audit.log` | `[spark-client][Audit][Spark] 26/02/26 00:00:34 INFO SparkContext: Running Spark version 3.5.6` |
| 2 | Application name and submission | `spark-logs/spark-audit.log` | `[spark-client][Audit][Spark] 26/02/26 00:00:34 INFO SparkContext: Submitted application: Spark Pi` |
| 3 | Spark uploads JARs to HDFS | `hadoop-logs/hdfs-audit-*.log` | `allowed=true ugi=spark cmd=create src=/user/spark/.sparkStaging/... proto=rpc` |
| 4 | YARN receives submit request | `hadoop-logs/rm-audit.log` | `USER=spark IP=172.18.0.5 OPERATION=Submit Application Request TARGET=ClientRMService RESULT=SUCCESS APPID=application_1772063068489_0001` |
| 5 | YARN allocates containers | `hadoop-logs/rm-audit.log` | `OPERATION=AM Allocated Container CONTAINERID=container_... RESOURCE=<memory:1024, vCores:1>` |
| 6 | Application Master registers | `hadoop-logs/rm-audit.log` | `OPERATION=Register App Master TARGET=ApplicationMasterService RESULT=SUCCESS APPID=...` |
| 7 | Job completes, containers released | `hadoop-logs/rm-audit.log` | `OPERATION=AM Released Container ...` then `OPERATION=Application Finished - Succeeded` |
| 8 | Spark driver logs completion | `spark-logs/spark-audit.log` | `INFO DAGScheduler: Job 0 finished` and `INFO SparkContext: Successfully stopped SparkContext` |

### SIEM / Correlation

- **Who submitted:** `USER=spark` in `rm-audit.log`
- **When (start):** Timestamp on `Submit Application Request`
- **When (end):** Timestamp on `Application Finished - Succeeded`
- **Application ID:** `APPID=application_1772063068489_0001` — use to correlate across all logs

---

## Scenario 2: Cluster Startup and Shutdown

**What happens:** `docker compose up -d` starts all services. Each daemon logs its startup.

### Startup Logs

| Component | Log File | What You See |
|-----------|----------|--------------|
| NameNode | `hadoop-logs/hadoop.log` (or namenode-specific) | Startup messages, loading fsimage, entering safe mode, leaving safe mode |
| DataNode | `hadoop-logs/hadoop.log` | Registering with NameNode, block reports |
| ResourceManager | `hadoop-logs/hadoop.log` | Starting services, recovering state |
| NodeManager | `hadoop-logs/hadoop.log` | Registering with ResourceManager |
| JobHistoryServer | `hadoop-logs/hadoop.log` | Starting web server on 19888 |
| Spark History Server | `spark-logs/spark-audit.log` or History Server stdout | Scanning HDFS for event logs |
| spark-client | `spark-logs/` | No logs until a job is submitted |

### Healthcheck Logs (UI Access)

Docker healthchecks `curl` the web UIs every 30 seconds. You will see:

| Log File | Example |
|----------|---------|
| `hadoop-logs/jetty-namenode.log` | `[][Access][NNDRFA] 127.0.0.1 - - [26/Feb/2026:00:00:11 +0000] "GET / HTTP/1.1" 302 0 "-" "curl/8.5.0"` |
| `hadoop-logs/jetty-resourcemanager.log` | Similar `GET /` from curl |
| `hadoop-logs/jetty-datanode.log` | Similar |
| `hadoop-logs/jetty-jobhistory.log` | Similar |
| `hadoop-logs/jetty-nodemanager.log` | Similar |

### Shutdown

On `docker compose down`, daemons stop. Logs may show "Shutting down" or similar. There is no dedicated shutdown audit in this setup; container exit is the signal.

---

## Scenario 3: HDFS CRUD (Create, Read, Update, Delete)

**What happens:** Any HDFS operation (creating dirs, writing files, reading, deleting) is audited by the NameNode.

### Log Location

`hadoop-logs/hdfs-audit-<hostname>.log` (e.g. `hdfs-audit-namenode.log` or `hdfs-audit-.log` if hostname is empty)

### Example Entries

| Operation | Example Log Line |
|-----------|------------------|
| **Read (getfileinfo)** | `allowed=true ugi=spark (auth:SIMPLE) ip=/172.18.0.7 cmd=getfileinfo src=/spark-history dst=null perm=null proto=rpc` |
| **List directory** | `allowed=true ugi=hdfs cmd=listStatus src=/user dst=null perm=null proto=rpc` |
| **Create file** | `allowed=true ugi=spark cmd=create src=/user/spark/.sparkStaging/application_xxx/file.zip dst=null perm=null proto=rpc` |
| **Delete** | `allowed=true ugi=spark cmd=delete src=/user/spark/.sparkStaging/... dst=null perm=null proto=rpc` |
| **Rename** | `allowed=true ugi=spark cmd=rename src=/path/old dst=/path/new perm=null proto=rpc` |

### Fields to Watch

- **ugi** — User (e.g. `spark`, `hdfs`, `mapred`)
- **cmd** — Command: `create`, `delete`, `getfileinfo`, `listStatus`, `rename`, etc.
- **src** / **dst** — Paths
- **allowed** — `true` or `false` (permission denied = `false`)

---

## Scenario 4: User Accesses a Web UI

**What happens:** Someone opens `http://localhost:8088` (YARN UI) or `http://localhost:18080` (Spark History) in a browser.

### Log Locations

| UI | Log File | Format |
|----|----------|--------|
| YARN ResourceManager (8088) | `hadoop-logs/jetty-resourcemanager.log` | NCSA-style access log |
| Spark History (18080) | `spark-logs/jetty-access.log` | `[hostname][Access][JETTY]` |
| HDFS NameNode (9870) | `hadoop-logs/jetty-namenode.log` | NCSA-style |
| Job History (19888) | `hadoop-logs/jetty-jobhistory.log` | NCSA-style |
| NodeManager (8042) | `hadoop-logs/jetty-nodemanager.log` | NCSA-style |
| Spark Driver (4040, when job runs) | `spark-logs/jetty-access.log` | Same as History |

### Example Entry

```
[][Access][NNDRFA] 127.0.0.1 - - [26/Feb/2026:00:00:11 +0000] "GET / HTTP/1.1" 302 0 "-" "curl/8.5.0"
```

- **IP** — Client IP (127.0.0.1 = localhost, e.g. from healthcheck or port-forward)
- **Request** — `GET /`, `GET /cluster/apps`, etc.
- **Status** — 200, 302, 404, 500
- **User-Agent** — Browser or `curl/8.5.0`

---

## Scenario 5: Failed Job Submission (Permission Denied)

**What happens:** User runs `spark-submit` but HDFS directories `/user/spark` or `/spark-history` do not exist or have wrong permissions.

### What You See

| Where | What You See |
|-------|--------------|
| **Terminal stdout** | `Permission denied: user=spark, access=WRITE, inode="/user/spark"` |
| **spark-logs/spark-audit.log** | `WARN` or `ERROR` with stack trace mentioning `PermissionDeniedException` |
| **hadoop-logs/hdfs-audit-*.log** | `allowed=false` for the create operation, or no entry if request fails before reaching NameNode |

### Remediation

Create dirs as per README:

```bash
docker exec -u hdfs spark-hadoop-namenode-1 hdfs dfs -mkdir -p /user/spark /spark-history
docker exec -u hdfs spark-hadoop-namenode-1 hdfs dfs -chmod -R 777 /user /spark-history
```

---

## Scenario 6: ResourceManager or NodeManager Down

**What happens:** ResourceManager or NodeManager container stops (crash, OOM, manual stop).

### Logs

| Component | Log File | What You See |
|-----------|----------|--------------|
| Spark client | `spark-logs/spark-audit.log` | `ERROR` or `WARN` — "Connection refused", "Failed to connect", "ApplicationMaster not registered" |
| YARN | `hadoop-logs/` | Last entries before crash; no new entries after restart |
| Docker | `docker compose logs resourcemanager` | JVM exit, OOM, or exception |

### Typical Failure Patterns

- **Connection refused** — Service not running or wrong host/port
- **OutOfMemoryError** — Increase heap in `*_OPTS` env vars
- **ApplicationMaster not registered** — RM restarted before AM could register; job retries or fails

---

## Scenario 7: Disk Space or Memory Issues (Error Conditions)

**What happens:** DataNode or NodeManager runs out of disk or memory.

### Where to Look

| Issue | Log Location | Typical Message |
|-------|--------------|-----------------|
| DataNode disk full | `hadoop-logs/hadoop.log` (or datanode-specific) | "No space left on device", "Disk full" |
| NodeManager OOM | `hadoop-logs/` | JVM exit, `OutOfMemoryError` |
| YARN container OOM | `hadoop-logs/` | Container killed, `exit code 137` (OOM kill) |
| hadoop-metrics2 | `hadoop-logs/*-metrics.out` | `DiskUsage`, `MemUsed` values |

### Metrics

- **hadoop-metrics2:** `hadoop-logs/namenode-metrics.out`, `datanode-metrics.out`, `nodemanager-metrics.out` — contain disk and memory metrics (if enabled)
- **Prometheus:** `http://localhost:4040/metrics/prometheus` (driver) or `http://localhost:18080/metrics/prometheus` (History Server) when job is running

---

## Scenario 8: API/SDK Programmatic Access

**What happens:** A script or application uses `hdfs dfs`, Spark API, or YARN REST API instead of a human using the UI.

### Logs (Same as Program Initiation)

- **spark-submit:** Same as Scenario 1 — `spark-audit.log`, `rm-audit.log` with `USER=` (the user running the process)
- **hdfs dfs:** `hdfs-audit-*.log` — `ugi` is the OS user (e.g. `root`, `spark`)
- **YARN REST API:** `jetty-resourcemanager.log` — HTTP requests with `GET /ws/v1/...` or similar

### Distinguishing Human vs API

- **User-Agent:** Browser vs `curl`, `python-requests`, etc.

---

## Scenario 9: Privileged User (hdfs) Operations

**What happens:** `docker exec -u hdfs ...` runs HDFS commands as the `hdfs` superuser.

### Logs

| Log File | What You See |
|----------|--------------|
| `hadoop-logs/hdfs-audit-*.log` | `ugi=hdfs (auth:SIMPLE) cmd=...` — all operations show `hdfs` as user |

### Example

```
allowed=true ugi=hdfs (auth:SIMPLE) ip=/172.18.0.5 cmd=mkdir src=/user/spark dst=null perm=null proto=rpc
```

---

## Quick Reference: Log File → Scenario

| Log File | Scenario |
|----------|----------|
| `spark-logs/spark-audit.log` | Program initiation (Spark), job lifecycle, errors |
| `hadoop-logs/rm-audit.log` | Program initiation (YARN), who submitted, when started/ended |
| `hadoop-logs/hdfs-audit-*.log` | HDFS CRUD, privileged user |
| `hadoop-logs/jetty-*.log` | UI access, startup healthchecks |
| `spark-logs/jetty-access.log` | Spark UI access |
| `hadoop-logs/hadoop.log` (or daemon-specific) | Startup, shutdown, errors, OOM |
