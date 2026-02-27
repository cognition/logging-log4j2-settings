#!/usr/bin/env bash
#
# Bundle Spark/Hadoop configuration for deployment to another system.
# Creates spark-hadoop-config-YYYYMMDD.tar.gz with configs, scripts, docs.
# Excludes logs, .git, tests.
#
# Usage: ./scripts/bundle-config.sh [output-dir]
#   output-dir: where to write the tar.gz (default: project root)
#
# On target host: extract, run ./scripts/fetch-hadoop-conf.sh, chmod 777 logs, docker compose up -d
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${1:-$REPO_ROOT}"
BUNDLE_NAME="spark-hadoop-config-$(date +%Y%m%d)"
TMP_DIR="${TMPDIR:-/tmp}/${BUNDLE_NAME}-$$"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TMP_DIR/$BUNDLE_NAME"
cd "$REPO_ROOT"

echo "Bundling configs into $BUNDLE_NAME..."

# Core files
cp docker-compose.yml "$TMP_DIR/$BUNDLE_NAME/"
cp README.md "$TMP_DIR/$BUNDLE_NAME/"

# Config directories (all contents)
cp -r hadoop-conf "$TMP_DIR/$BUNDLE_NAME/"
cp -r spark-conf "$TMP_DIR/$BUNDLE_NAME/"

# Optional config dirs (when present)
for d in hive-conf hbase-conf pig-conf; do
  if [[ -d "$d" ]]; then
    cp -r "$d" "$TMP_DIR/$BUNDLE_NAME/"
  fi
done

# Scripts (only the deployment scripts)
mkdir -p "$TMP_DIR/$BUNDLE_NAME/scripts"
cp scripts/fetch-hadoop-conf.sh scripts/test-spark-yarn.sh scripts/bundle-config.sh scripts/sync-hdfs-logs-to-local.sh "$TMP_DIR/$BUNDLE_NAME/scripts/"

# Docs
cp -r docs "$TMP_DIR/$BUNDLE_NAME/"

# JMX exporter config
if [[ -d jmx-exporter-config ]]; then
  cp -r jmx-exporter-config "$TMP_DIR/$BUNDLE_NAME/"
fi

# Azure DCR for HDFS logs
if [[ -d azure ]]; then
  cp -r azure "$TMP_DIR/$BUNDLE_NAME/"
fi

# Ansible role and playbook
if [[ -d ansible ]]; then
  cp -r ansible "$TMP_DIR/$BUNDLE_NAME/"
fi

# Empty logs directory with .gitkeep
mkdir -p "$TMP_DIR/$BUNDLE_NAME/logs"
touch "$TMP_DIR/$BUNDLE_NAME/logs/.gitkeep"

# Optional DEPLOY.md (quick deploy instructions)
cat > "$TMP_DIR/$BUNDLE_NAME/DEPLOY.md" << 'DEPLOY_EOF'
# Deploy Spark/Hadoop Logging Config

1. Extract: `tar -xzf spark-hadoop-config-*.tar.gz && cd spark-hadoop-config-*`
2. Fetch Hadoop config: `./scripts/fetch-hadoop-conf.sh`
3. Prepare logs: `chmod 777 logs`
4. Start cluster: `docker compose up -d`
5. Verify: `./scripts/test-spark-yarn.sh`

Optional: Run Ansible to apply toggles or syslog — see docs/ANSIBLE.md.

See README.md and docs/ for full documentation.
DEPLOY_EOF

# Create archive
mkdir -p "$OUTPUT_DIR"
tar -czf "$OUTPUT_DIR/${BUNDLE_NAME}.tar.gz" -C "$TMP_DIR" "$BUNDLE_NAME"

echo "Created $OUTPUT_DIR/${BUNDLE_NAME}.tar.gz"
echo "To deploy: tar -xzf ${BUNDLE_NAME}.tar.gz && cd $BUNDLE_NAME && ./scripts/fetch-hadoop-conf.sh && chmod 777 logs && docker compose up -d"
