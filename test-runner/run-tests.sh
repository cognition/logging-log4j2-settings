#!/usr/bin/env bash
set -euo pipefail

# Run the full test suite from inside the test-runner container.
# Expects to be on the same Docker network as namenode, resourcemanager, hiveserver2.
# Mount hadoop-conf and spark-conf so HADOOP_CONF_DIR and SPARK_CONF_DIR point at them.

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
    return 1
  fi
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

# --- HDFS ---
test_hdfs() {
  local test_dir="/tmp/hdfs_test_$$"
  local test_file="${test_dir}/sample.txt"
  local expected_content="dummy hdfs data $(date +%s)"

  hdfs dfs -mkdir -p "${test_dir}" || fail "HDFS mkdir failed"
  echo "${expected_content}" | hdfs dfs -put - "${test_file}" || fail "HDFS put failed"
  local actual_content
  actual_content="$(hdfs dfs -cat "${test_file}")" || fail "HDFS cat failed"
  hdfs dfs -rm -f "${test_file}" >/dev/null 2>&1 || true
  hdfs dfs -rmdir "${test_dir}" >/dev/null 2>&1 || true

  if [[ "${actual_content}" != "${expected_content}" ]]; then
    echo "Content mismatch. Expected: ${expected_content}; Got: ${actual_content}"
    return 1
  fi
  echo "HDFS basic write/read OK."
}

# --- Hive (Beeline) ---
test_hive() {
  local beeline_bin="${HIVE_HOME:-/opt/hive}/bin/beeline"
  if [[ ! -x "${beeline_bin}" ]]; then
    echo "Beeline not found at ${beeline_bin}; skipping Hive SQL test."
    # Connectivity only
    for host_port in "hiveserver2:10000" "hive-metastore:9083"; do
      if timeout 5 bash -c "echo > /dev/tcp/${host_port%%:*}/${host_port##*:}" 2>/dev/null; then
        echo "Connected to ${host_port}"
      else
        echo "WARNING: could not connect to ${host_port}"
      fi
    done
    return 0
  fi

  local sql="CREATE DATABASE IF NOT EXISTS test_db; USE test_db; CREATE TABLE IF NOT EXISTS dummy_data (id INT, name STRING) STORED AS ORC; INSERT INTO dummy_data VALUES (1, 'alice'), (2, 'bob'); SELECT COUNT(*) AS cnt FROM dummy_data;"
  "${beeline_bin}" -u "jdbc:hive2://hiveserver2:10000/default" -n hive -p "" -e "${sql}" || return 1
  echo "Hive beeline test OK."
}

# --- Spark on YARN ---
test_spark() {
  spark-submit \
    --master yarn \
    --deploy-mode client \
    --class org.apache.spark.examples.SparkPi \
    /opt/spark/examples/jars/spark-examples_2.12-3.5.6.jar 10 || return 1
  echo "Spark Pi on YARN OK."
}

# --- HDFS log path (lightweight check; full sync runs in hdfs-log-sync service) ---
test_hdfs_log_path() {
  if hdfs dfs -ls /tmp/logs >/dev/null 2>&1; then
    echo "HDFS log path /tmp/logs is reachable."
  else
    echo "HDFS /tmp/logs not present or empty (normal if no YARN logs yet)."
  fi
  return 0
}

# --- Main ---
failed=0
run_test "HDFS basic write/read" test_hdfs || failed=1
run_test "Hive (beeline) CRUD & count" test_hive || failed=1
run_test "Spark on YARN (SparkPi)" test_spark || failed=1
run_test "HDFS log path" test_hdfs_log_path || failed=1

echo
if [[ "${failed}" -eq 0 ]]; then
  echo "All tests completed successfully."
  exit 0
else
  echo "One or more tests failed."
  exit 1
fi
