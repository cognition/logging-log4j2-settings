#!/usr/bin/env bash
set -euo pipefail

# Sync YARN container/task logs from HDFS to a local file for ingestion.

HADOOP_BIN="${HADOOP_BIN:-hdfs}"
HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-/etc/hadoop/conf}"
HDFS_LOG_DIR="${HDFS_LOG_DIR:-/tmp/logs}"
OUTPUT_DIR="${OUTPUT_DIR:-/logs/hdfs-container-logs}"

mkdir -p "${OUTPUT_DIR}"

export HADOOP_CONF_DIR

TMP_FILE="$(mktemp "${OUTPUT_DIR}/yarn-container-logs.XXXXXX")"

${HADOOP_BIN} dfs -text "${HDFS_LOG_DIR}/**" > "${TMP_FILE}" 2>/dev/null || true

if [[ -s "${TMP_FILE}" ]]; then
  mv "${TMP_FILE}" "${OUTPUT_DIR}/yarn-container-logs.log"
else
  rm -f "${TMP_FILE}"
fi

