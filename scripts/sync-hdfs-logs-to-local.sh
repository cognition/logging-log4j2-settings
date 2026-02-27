#!/usr/bin/env bash
#
# Sync YARN aggregated container logs from HDFS to a local directory.
# Azure Monitor Agent can then collect from the local files via a Custom Text Logs DCR.
#
# HDFS path: yarn.nodemanager.remote-app-log-dir (default /tmp/logs)
# Structure: /tmp/logs/{user}/logs/{application_id}/*.log
#
# Usage:
#   ./scripts/sync-hdfs-logs-to-local.sh
#   HDFS_LOG_DIR=/custom/path OUTPUT_DIR=/custom/out ./scripts/sync-hdfs-logs-to-local.sh
#
# Environment:
#   HDFS_LOG_DIR   - HDFS path for YARN log aggregation (default: /tmp/logs)
#   OUTPUT_DIR     - Local directory for synced logs (default: /logs/hdfs-container-logs)
#   HADOOP_CONF_DIR - Hadoop config (must be set for hdfs command)
#
set -euo pipefail

HDFS_LOG_DIR="${HDFS_LOG_DIR:-/tmp/logs}"
OUTPUT_DIR="${OUTPUT_DIR:-/logs/hdfs-container-logs}"
STATE_FILE="${OUTPUT_DIR}/.sync-state"
OUTPUT_FILE="${OUTPUT_DIR}/yarn-container-logs.log"

mkdir -p "$OUTPUT_DIR"

if [[ -z "${HADOOP_CONF_DIR:-}" ]]; then
  echo "HADOOP_CONF_DIR must be set" >&2
  exit 1
fi

# Ensure output file exists for append
touch "$OUTPUT_FILE"

# Get list of all log files in HDFS (recursive)
# Format: -rw-r--r--   3 root hadoop     1234 2024-01-15 10:00 hdfs://...path
# We extract the full path
get_hdfs_files() {
  # Include .log, .stdout, .stderr, .syslog (YARN aggregated formats)
  hdfs dfs -ls -R "$HDFS_LOG_DIR" 2>/dev/null | awk '/^-/ {print $NF}' | grep -E '\.(log|log\.gz|stdout|stderr|syslog)$' || true
}

# Load already-processed paths
declare -A PROCESSED
if [[ -f "$STATE_FILE" ]]; then
  while IFS= read -r p; do
    [[ -n "$p" ]] && PROCESSED["$p"]=1
  done < "$STATE_FILE"
fi

# Process new files
NEW_COUNT=0
TMP_STATE=$(mktemp)
trap 'rm -f "$TMP_STATE"' EXIT

while IFS= read -r hdfs_path; do
  [[ -z "$hdfs_path" ]] && continue
  if [[ -n "${PROCESSED[$hdfs_path]:-}" ]]; then
    echo "$hdfs_path" >> "$TMP_STATE"
    continue
  fi

  # Append file content with a header for traceability
  {
    echo "--- [HDFS:$hdfs_path] $(date -Iseconds) ---"
    hdfs dfs -cat "$hdfs_path" 2>/dev/null || true
    echo ""
  } >> "$OUTPUT_FILE"
  echo "$hdfs_path" >> "$TMP_STATE"
  ((NEW_COUNT++)) || true
done < <(get_hdfs_files)

# Update state with any newly discovered paths (from this run's output)
while IFS= read -r p; do
  [[ -n "$p" ]] && echo "$p"
done < "$TMP_STATE" | sort -u > "$STATE_FILE"

if [[ "$NEW_COUNT" -gt 0 ]]; then
  echo "Synced $NEW_COUNT new log file(s) from HDFS to $OUTPUT_FILE"
fi
