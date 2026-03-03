#!/usr/bin/env bash
set -euo pipefail

# Basic HDFS sanity check: write dummy data, read it back, and verify.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running basic HDFS write/read test via namenode container..."

docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T namenode \
  bash -lc '
    set -euo pipefail
    TEST_DIR="/tmp/hdfs_test"
    TEST_FILE_LOCAL="/tmp/hdfs_test_$$.txt"
    TEST_FILE_HDFS="${TEST_DIR}/sample.txt"
    EXPECTED_CONTENT="dummy hdfs data $(date +%s)"

    echo "${EXPECTED_CONTENT}" > "${TEST_FILE_LOCAL}"

    bin/hdfs dfs -mkdir -p "${TEST_DIR}"
    bin/hdfs dfs -put -f "${TEST_FILE_LOCAL}" "${TEST_FILE_HDFS}"

    ACTUAL_CONTENT="$(bin/hdfs dfs -cat "${TEST_FILE_HDFS}")"

    if [[ "${ACTUAL_CONTENT}" != "${EXPECTED_CONTENT}" ]]; then
      echo "HDFS test FAILED: content mismatch."
      echo "Expected: ${EXPECTED_CONTENT}"
      echo "Actual:   ${ACTUAL_CONTENT}"
      exit 1
    fi

    echo "HDFS basic write/read test passed."
  '

echo "HDFS test completed successfully."

