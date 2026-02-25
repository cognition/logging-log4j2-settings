#!/usr/bin/env bash
#
# Submit a Spark job to YARN for logging verification.
# Run from host: ./scripts/test-spark-yarn.sh
# Or exec into spark-client: spark-submit --class org.apache.spark.examples.SparkPi /opt/spark/examples/jars/spark-examples_2.12-3.5.6.jar 10
#
# Prerequisites:
#   - docker compose up (YARN cluster running)
#   - ./scripts/fetch-hadoop-conf.sh (Hadoop config in hadoop-conf/)
#
set -euo pipefail

CONTAINER="${SPARK_CLIENT_CONTAINER:-spark-hadoop-spark-client-1}"
EXAMPLE_JAR="/opt/spark/examples/jars/spark-examples_2.12-3.5.6.jar"

echo "Submitting Spark Pi example to YARN as current user..."
docker exec "$CONTAINER" /opt/spark/bin/spark-submit \
  --class org.apache.spark.examples.SparkPi \
  --deploy-mode client \
  "$EXAMPLE_JAR" \
  10

echo "---"
echo "Done. Check spark-logs/ and hadoop-logs/ for user and job in logs."
echo "YARN UI: http://localhost:8088"
echo "Spark History: http://localhost:18080"
