# Azure Monitor: Ingesting HDFS Container Logs

This guide explains how to connect Azure Monitor (Log Analytics) to YARN container logs that are aggregated in HDFS. These logs contain stdout, stderr, and syslog from Spark executors and other YARN containers—valuable for operational monitoring and incident detection.

## Overview

| Log source | Location | How Azure gets it |
|------------|----------|-------------------|
| Daemon/audit logs | Host `./logs` | Azure Monitor Agent → Custom Text Logs DCR |
| HDFS container logs | HDFS `/tmp/logs` | Sync script → local file → Azure Monitor Agent |

The sync script (`scripts/sync-hdfs-logs-to-local.sh`) periodically copies YARN aggregated logs from HDFS to a local directory. Azure Monitor Agent then collects from that directory via a Data Collection Rule (DCR).

## Sandbox (Docker Compose)

The `hdfs-log-sync` service runs the sync script every 5 minutes. Output is written to `./logs/hdfs-container-logs/yarn-container-logs.log`.

1. Start the cluster: `docker compose up -d`
2. Run a Spark job so container logs appear in HDFS: `./scripts/test-spark-yarn.sh`
3. Wait a few minutes for sync. Check: `tail -f logs/hdfs-container-logs/yarn-container-logs.log`

## Production Deployment

### 1. Run the sync script

The script must run on a host that has:

- HDFS client (`hdfs dfs` or equivalent)
- `HADOOP_CONF_DIR` pointing to your Hadoop config
- Network access to the NameNode

**Option A: Cron**

```bash
# Every 5 minutes
*/5 * * * * HADOOP_CONF_DIR=/etc/hadoop/conf OUTPUT_DIR=/var/log/hdfs-container-logs /path/to/sync-hdfs-logs-to-local.sh
```

**Option B: Systemd timer**

Create `/etc/systemd/system/hdfs-log-sync.service`:

```ini
[Unit]
Description=Sync HDFS container logs to local
After=network.target

[Service]
Type=oneshot
Environment=HADOOP_CONF_DIR=/etc/hadoop/conf
Environment=OUTPUT_DIR=/var/log/hdfs-container-logs
ExecStart=/path/to/sync-hdfs-logs-to-local.sh
```

Create `/etc/systemd/system/hdfs-log-sync.timer`:

```ini
[Unit]
Description=Run HDFS log sync every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

Enable: `systemctl enable --now hdfs-log-sync.timer`

### 2. Configure Azure Monitor Agent

1. **Install Azure Monitor Agent** on the host where the sync script writes (or on an Azure Arc–enabled server).

2. **Create a custom table** in your Log Analytics workspace:

   - Name: `HDFSYarnContainerLogs_CL` (must end with `_CL`)
   - Columns: `TimeGenerated` (datetime), `RawData` (string), optionally `Computer`, `FilePath`

3. **Create a Data Collection Rule (DCR)** with **Custom Text Logs** data source:

   - **File pattern**: `/var/log/hdfs-container-logs/yarn-container-logs.log` (or your `OUTPUT_DIR`)
   - **Table name**: `HDFSYarnContainerLogs_CL`
   - **Record delimiter**: Use `TimeStamp` if your log lines start with timestamps; otherwise `Newline`
   - **Transform**: `source` (no transformation) or a KQL query to parse fields

4. **Associate the DCR** with the VM or Arc server.

See [Collect logs from text files with Azure Monitor Agent](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/data-collection-log-text) for detailed steps.

### KQL Queries

Documented KQL queries for all ingested logs (HDFS container, audit, access, incident detection) are in [azure/queries/](../azure/queries/README.md).

### Deploy DCR via Script

This repo includes an ARM template and deployment script:

```bash
./azure/deploy-dcr.sh <resource-group> <workspace-name> [log-file-pattern]
```

See [azure/README.md](../azure/README.md) for details.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HDFS_LOG_DIR` | `/tmp/logs` | HDFS path for YARN log aggregation (`yarn.nodemanager.remote-app-log-dir`) |
| `OUTPUT_DIR` | `/logs/hdfs-container-logs` | Local directory for synced logs |
| `HADOOP_CONF_DIR` | (required) | Path to Hadoop config (core-site.xml, hdfs-site.xml, etc.) |

## YARN Configuration

Ensure log aggregation is enabled in `yarn-site.xml`:

```xml
<property>
  <name>yarn.log-aggregation-enable</name>
  <value>true</value>
</property>
```

The default aggregation path is `/tmp/logs`. To use a different path, set `yarn.nodemanager.remote-app-log-dir` and pass the same value as `HDFS_LOG_DIR` to the sync script.

## Alternative: Logs Ingestion API

For environments where the Azure Monitor Agent cannot run on the same host as the sync script, you can push logs directly to Azure using the [Logs Ingestion API](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/logs-ingestion-api-overview). Modify the sync script to call the API (e.g., via `curl` or a small Python helper) instead of writing to a local file. This requires a DCR with the appropriate stream and authentication (managed identity or service principal).
