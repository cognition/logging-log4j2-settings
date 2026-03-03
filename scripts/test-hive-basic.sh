#!/usr/bin/env bash
set -euo pipefail

# Basic Hive sanity check: create a database/table, insert dummy data, and query it.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running basic Hive test via hive-server container..."

docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T hive-server \
  bash -lc '
    set -euo pipefail

    SQL="
      CREATE DATABASE IF NOT EXISTS test_db;
      USE test_db;
      CREATE TABLE IF NOT EXISTS dummy_data (
        id   INT,
        name STRING
      )
      STORED AS ORC;
      INSERT INTO dummy_data VALUES (1, \"alice\"), (2, \"bob\");
      SELECT COUNT(*) AS cnt FROM dummy_data;
    "

    echo "Submitting Hive SQL:"
    echo "${SQL}"

    # Prefer beeline if present, otherwise fall back to the Hive CLI.
    if command -v beeline >/dev/null 2>&1; then
      beeline -u \"jdbc:hive2://hiveserver2:10000/default\" -n hive -p \"\" -e \"${SQL}\"
    elif command -v hive >/dev/null 2>&1; then
      hive -e \"${SQL}\"
    else
      echo "Hive CLI (beeline/hive) not available in this image."
      echo "Falling back to a basic TCP connectivity check to HiveServer2 and Metastore."

      # Basic connectivity checks using bash's /dev/tcp pseudo-device.
      for host_port in \"hiveserver2:10000\" \"hive-metastore:9083\"; do
        host=\"${host_port%%:*}\"
        port=\"${host_port##*:}\"
        echo "Checking ${host}:${port}..."
        if bash -c "echo > /dev/tcp/${host}/${port}" >/dev/null 2>&1; then
          echo "Successfully connected to ${host}:${port}"
        else
          echo "WARNING: Could not connect to ${host}:${port}"
        fi
      done

      echo "Hive basic connectivity test completed (no CLI available for SQL)."
    fi
  '

echo "Hive test completed. Review output above for row count and any errors."

