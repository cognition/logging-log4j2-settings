#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper to run the full test suite against the Hadoop/Spark/Hive stack.
#
# Assumes the cluster is already up:
#   docker compose up -d

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="${ROOT_DIR}/scripts"

run_test() {
  local name="$1"
  shift
  echo
  echo "============================================================"
  echo "Running test: ${name}"
  echo "============================================================"
  if "$@"; then
    echo "Test ${name} PASSED"
  else
    echo "Test ${name} FAILED"
    exit 1
  fi
}

run_test "HDFS basic write/read"      "${SCRIPTS_DIR}/test-hdfs-basic.sh"
run_test "Hive basic CRUD & count"    "${SCRIPTS_DIR}/test-hive-basic.sh"
run_test "Spark on YARN (SparkPi)"    "${SCRIPTS_DIR}/test-spark-yarn.sh"
run_test "HDFS log sync helper"       "${SCRIPTS_DIR}/test-log-sync.sh"

echo
echo "All tests completed."

