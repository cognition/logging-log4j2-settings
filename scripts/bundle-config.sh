#!/usr/bin/env bash
set -euo pipefail

# Create a deployable bundle for VM/physical server deployment.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/dist"
TS="$(date +%Y%m%d-%H%M%S)"
BUNDLE_NAME="hadoop-logging-bundle-${TS}.tar.gz"

mkdir -p "${OUT_DIR}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p \
  "${TMP_DIR}/hadoop-conf" \
  "${TMP_DIR}/spark-conf" \
  "${TMP_DIR}/scripts" \
  "${TMP_DIR}/docs"

cp -R "${ROOT_DIR}/hadoop-conf/." "${TMP_DIR}/hadoop-conf/"
cp -R "${ROOT_DIR}/spark-conf/." "${TMP_DIR}/spark-conf/"
cp -R "${ROOT_DIR}/scripts/." "${TMP_DIR}/scripts/"

# Env template for VM/physical deployment (LOG_DIR, LOG_TAG_*, syslog)
cat > "${TMP_DIR}/env.example" <<'EOF'
# Example environment for VM/physical deployment
export LOG_DIR=/var/log/hadoop-logging

# Optional log tags (include brackets if desired, e.g. "[prod]")
export LOG_TAG_APPLICATION=
export LOG_TAG_ACTION=
export LOG_TAG_SECURITY=
export LOG_TAG_CUSTOM=

# Optional syslog forwarding
export SYSLOG_HOST=localhost
export SYSLOG_PORT=514
export SYSLOG_PROTOCOL=UDP
export SYSLOG_FACILITY=LOCAL1
EOF

tar -C "${TMP_DIR}" -czf "${OUT_DIR}/${BUNDLE_NAME}" .

echo "Created bundle: ${OUT_DIR}/${BUNDLE_NAME}"

