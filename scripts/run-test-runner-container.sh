#!/usr/bin/env bash
set -euo pipefail

# Build the test-runner image, then run it on the same network as the stack.
# The container runs the test suite and exits (no daemon).
#
# Prereqs: stack is up (docker compose up -d). Run from repo root.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

IMAGE_NAME="${TEST_RUNNER_IMAGE:-spark-hadoop-test-runner}"

# Resolve compose project network (e.g. hadoop-logging-apache_default)
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-hadoop-logging-apache}"
NETWORK="${TEST_RUNNER_NETWORK:-${COMPOSE_PROJECT_NAME}_default}"

# If network does not exist, infer from a running namenode container
if ! docker network inspect "${NETWORK}" >/dev/null 2>&1; then
  nn_id="$(docker compose -f "${ROOT_DIR}/docker-compose.yml" ps -q namenode 2>/dev/null | head -1)"
  if [[ -n "${nn_id}" ]]; then
    detected="$(docker inspect "${nn_id}" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null)"
    if [[ -n "${detected}" ]]; then
      NETWORK="${detected}"
    fi
  fi
  if ! docker network inspect "${NETWORK}" >/dev/null 2>&1; then
    echo "ERROR: Network ${NETWORK} not found. Is the stack running? (docker compose up -d)" >&2
    exit 1
  fi
fi

echo "Building test-runner image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" -f test-runner/Dockerfile .

echo "Running test-runner container on network: ${NETWORK}"
docker run --rm \
  --network "${NETWORK}" \
  -v "${ROOT_DIR}/hadoop-conf:/opt/hadoop/etc/hadoop:ro" \
  -v "${ROOT_DIR}/spark-conf:/opt/spark/conf:ro" \
  -e HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
  -e SPARK_CONF_DIR=/opt/spark/conf \
  "${IMAGE_NAME}"
