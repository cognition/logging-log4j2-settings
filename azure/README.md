# Azure Monitor DCR for HDFS Container Logs

Deploy a Data Collection Rule (DCR) so Azure Monitor Agent can collect HDFS YARN container logs.

## Prerequisites

- Azure CLI (`az`) installed and logged in
- Log Analytics workspace
- Sync script writing logs to a local path (see [AZURE_MONITOR_HDFS_LOGS.md](../docs/AZURE_MONITOR_HDFS_LOGS.md))

## Quick Deploy

```bash
./azure/deploy-dcr.sh <resource-group> <workspace-name> [log-file-pattern]
```

**Examples:**

```bash
# Production: logs at /var/log/hdfs-container-logs/
./azure/deploy-dcr.sh my-rg my-log-analytics-workspace

# Sandbox: logs at project logs/hdfs-container-logs/
./azure/deploy-dcr.sh my-rg my-workspace "/home/user/spark-hadoop/logs/hdfs-container-logs/*.log"
```

## Manual Deploy (ARM Template)

1. Edit `dcr-hdfs-logs.parameters.json` and set `workspaceResourceId` and `logFilePattern`.

2. Create the custom table:

```bash
az monitor log-analytics workspace table create \
  --resource-group <rg> \
  --workspace-name <workspace> \
  --name HDFSYarnContainerLogs_CL \
  --columns TimeGenerated=datetime RawData=string Computer=string FilePath=string
```

3. Deploy the template:

```bash
az deployment group create \
  --resource-group <rg> \
  --template-file azure/dcr-hdfs-logs.json \
  --parameters @azure/dcr-hdfs-logs.parameters.json
```

## Associate DCR with a VM

After deploying, associate the DCR with the machine where the sync script writes logs:

```bash
# Azure VM
az monitor data-collection rule association create \
  --name dcra-hdfs-logs \
  --resource /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Compute/virtualMachines/<vm> \
  --rule-id /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Insights/dataCollectionRules/dcr-hdfs-yarn-container-logs

# Azure Arc-enabled server
az monitor data-collection rule association create \
  --name dcra-hdfs-logs \
  --resource /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.HybridCompute/machines/<arc-server> \
  --rule-id /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Insights/dataCollectionRules/dcr-hdfs-yarn-container-logs
```

## Query Logs

See **[azure/queries/README.md](queries/README.md)** for documented KQL queries covering:

- HDFS container logs (failures, OOM, exceptions)
- Audit logs (HDFS, YARN, Spark)
- Access logs (Jetty UI access)
- Incident detection (alerts, permission denied)
- Operational dashboards (counts, trends)

Quick example:

```kusto
HDFSYarnContainerLogs_CL
| where TimeGenerated > ago(1h)
| project TimeGenerated, Computer, RawData
| order by TimeGenerated desc
```
