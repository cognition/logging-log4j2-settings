#!/usr/bin/env bash
set -euo pipefail

# Validate that the HDFS log sync helper can run and that the local
# output directory exists / is populated.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running HDFS log sync test via hdfs-log-sync container..."

docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T hdfs-log-sync \
  bash -lc '
    set -euo pipefail

    # Reuse the same environment variables that the service uses by default.
    : "${HADOOP_BIN:=/opt/hadoop/bin/hdfs}"
    : "${HDFS_LOG_DIR:=/tmp/logs}"
    : "${OUTPUT_DIR:=/logs/hdfs-container-logs}"

    echo "Using HADOOP_BIN=${HADOOP_BIN}"
    echo "Using HDFS_LOG_DIR=${HDFS_LOG_DIR}"
    echo "Using OUTPUT_DIR=${OUTPUT_DIR}"

    # Run a single sync pass. The underlying script is idempotent.
    bash /scripts/sync-hdfs-logs-to-local.sh

    if [[ ! -d "${OUTPUT_DIR}" ]]; then
      echo "Log sync test FAILED: output directory ${OUTPUT_DIR} does not exist."
      exit 1
    fi

    echo "Log sync output directory exists: ${OUTPUT_DIR}"

    if find "${OUTPUT_DIR}" -maxdepth 1 -type f | grep -q .; then
      echo "Log sync test passed: at least one log file present in ${OUTPUT_DIR}."
    else
      echo "Log sync ran successfully, but no log files were found in ${OUTPUT_DIR}."
      echo "This can be normal if the cluster has not yet produced container logs."
    fi
  '

echo "HDFS log sync test script completed."

