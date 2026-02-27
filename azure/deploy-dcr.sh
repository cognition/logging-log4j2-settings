#!/usr/bin/env bash
#
# Deploy the Data Collection Rule (DCR) for HDFS YARN container logs.
# Prerequisites: Azure CLI (az), Log Analytics workspace.
#
# Usage:
#   ./azure/deploy-dcr.sh <resource-group> <workspace-name> [log-file-pattern]
#
# Example:
#   ./azure/deploy-dcr.sh my-rg my-log-analytics-workspace
#   ./azure/deploy-dcr.sh my-rg my-workspace "/home/user/spark-hadoop/logs/hdfs-container-logs/*.log"
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCE_GROUP="${1:?Usage: $0 <resource-group> <workspace-name> [log-file-pattern]}"
WORKSPACE_NAME="${2:?Usage: $0 <resource-group> <workspace-name> [log-file-pattern]}"
LOG_FILE_PATTERN="${3:-/var/log/hdfs-container-logs/*.log}"

# Get workspace resource ID and location
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$WORKSPACE_NAME" \
  --query id -o tsv)
LOCATION=$(az monitor log-analytics workspace show \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$WORKSPACE_NAME" \
  --query location -o tsv)

echo "Creating custom table HDFSYarnContainerLogs_CL (if not exists)..."
az monitor log-analytics workspace table create \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$WORKSPACE_NAME" \
  --name "HDFSYarnContainerLogs_CL" \
  --columns "TimeGenerated=datetime RawData=string Computer=string FilePath=string" \
  2>/dev/null || echo "Table may already exist, continuing..."

echo "Deploying DCR..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$SCRIPT_DIR/dcr-hdfs-logs.json" \
  --parameters \
    workspaceResourceId="$WORKSPACE_ID" \
    logFilePattern="$LOG_FILE_PATTERN" \
    location="$LOCATION" \
  --query "properties.outputs" -o json

echo ""
echo "DCR deployed. Next steps:"
echo "1. Install Azure Monitor Agent on the VM/Arc server where logs are written"
echo "2. Associate the DCR with the machine:"
echo "   az monitor data-collection rule association create \\"
echo "     --name dcra-hdfs-logs \\"
echo "     --resource <VM_OR_ARC_RESOURCE_ID> \\"
echo "     --rule-id <DCR_RESOURCE_ID>"
