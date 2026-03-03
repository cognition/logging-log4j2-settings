#!/usr/bin/env bash
set -euo pipefail

# Submit a simple Spark job to the YARN cluster from the spark-client container.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T spark-client \
  /opt/spark/bin/spark-submit \
    --master yarn \
    --deploy-mode client \
    --class org.apache.spark.examples.SparkPi \
    /opt/spark/examples/jars/spark-examples_2.12-3.5.6.jar 10

echo "Spark Pi submitted via YARN. Check logs under logs/ for audit and application output."

