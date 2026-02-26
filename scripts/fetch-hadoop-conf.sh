#!/usr/bin/env bash
#
# Fetch Hadoop configuration from hadoop-sandbox for YARN + HDFS.
# Run once before first docker compose up.
#
set -euo pipefail

REPO_URL="https://github.com/hadoop-sandbox/hadoop-sandbox.git"
CONF_DIR="$(cd "$(dirname "$0")/.." && pwd)/hadoop-conf"
TMP_DIR="${TMPDIR:-/tmp}/hadoop-sandbox-conf-$$"

mkdir -p "$CONF_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Fetching Hadoop config from hadoop-sandbox..."
git clone --depth 1 "$REPO_URL" "$TMP_DIR"

echo "Copying conf/hadoop to $CONF_DIR..."
cp -r "$TMP_DIR/conf/hadoop/"* "$CONF_DIR/"

# Remove Log4j 1.x configs; this repo uses Log4j 2 (log4j2.properties, etc.)
rm -f "$CONF_DIR"/log4j.properties "$CONF_DIR"/kms-log4j.properties \
      "$CONF_DIR"/httpfs-log4j.properties "$CONF_DIR"/yarnservice-log4j.properties 2>/dev/null || true

echo "Done. Hadoop config in $CONF_DIR"
