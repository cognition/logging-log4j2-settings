# Scripts — Line-by-Line Reference

Bash scripts for setup and testing. Reference: [Bash Manual](https://www.gnu.org/software/bash/manual/).

---

## scripts/fetch-hadoop-conf.sh

Fetches Hadoop configuration from the hadoop-sandbox repository. **Run once** before first `docker compose up`.

| Line | Content | What It Does |
|------|---------|--------------|
| 1 | `#!/usr/bin/env bash` | Shebang: run with bash |
| 2–5 | `#` comments | Describes purpose and when to run |
| 6 | `set -euo pipefail` | Strict mode: exit on error (`-e`), undefined vars (`-u`), pipe failures (`pipefail`) |
| 8 | `REPO_URL="https://github.com/hadoop-sandbox/hadoop-sandbox.git"` | Source repository for Hadoop config |
| 9 | `CONF_DIR="$(cd "$(dirname "$0")/.." && pwd)/hadoop-conf"` | Target directory: `hadoop-conf` in project root. `$0` = script path |
| 10 | `TMP_DIR="${TMPDIR:-/tmp}/hadoop-sandbox-conf-$$"` | Temp directory. `$$` = process ID (unique per run) |
| 12 | `mkdir -p "$CONF_DIR"` | Create hadoop-conf if it doesn't exist |
| 13 | `trap 'rm -rf "$TMP_DIR"' EXIT` | Delete temp dir when script exits (success or failure) |
| 15 | `echo "Fetching Hadoop config..."` | User message |
| 16 | `git clone --depth 1 "$REPO_URL" "$TMP_DIR"` | Shallow clone (no history). Saves time and space |
| 18 | `echo "Copying conf/hadoop to $CONF_DIR..."` | User message |
| 19 | `cp -r "$TMP_DIR/conf/hadoop/"* "$CONF_DIR/"` | Copy all files from repo's `conf/hadoop/` to `hadoop-conf/` |
| 21 | `echo "Done. Hadoop config in $CONF_DIR"` | Completion message |

**Prerequisite**: `git` must be installed.

---

## scripts/test-spark-yarn.sh

Submits a sample Spark job (Pi estimation) to YARN. Used to verify the cluster and logging.

| Line | Content | What It Does |
|------|---------|--------------|
| 1 | `#!/usr/bin/env bash` | Shebang |
| 2–10 | `#` comments | Purpose, usage, prerequisites |
| 11 | `set -euo pipefail` | Strict mode |
| 13 | `CONTAINER="${SPARK_CLIENT_CONTAINER:-spark-hadoop-spark-client-1}"` | Container name. Override with env var for different compose project names |
| 14 | `EXAMPLE_JAR="/opt/spark/examples/jars/spark-examples_2.12-3.5.6.jar"` | Path to Spark Pi example JAR inside container |
| 16 | `echo "Submitting Spark Pi example to YARN as current user..."` | User message |
| 17–21 | `docker exec "$CONTAINER" /opt/spark/bin/spark-submit \` | Run spark-submit inside spark-client container |
| 18 | `--class org.apache.spark.examples.SparkPi` | Main class (computes Pi via Monte Carlo) |
| 19 | `--deploy-mode client` | Driver on spark-client (matches spark-defaults.conf) |
| 20 | `"$EXAMPLE_JAR"` | Application JAR |
| 21 | `10` | Argument: number of partitions (more = more parallelism) |
| 23–26 | `echo` | Post-run messages: where to check logs, UI URLs |

**Prerequisites**:
- `docker compose up -d` (cluster running)
- `./scripts/fetch-hadoop-conf.sh` (Hadoop config present)

**Override container name**: `SPARK_CLIENT_CONTAINER=my-spark-client ./scripts/test-spark-yarn.sh`

---

## scripts/bundle-config.sh

Bundles Spark/Hadoop configuration for deployment to another system. Creates `spark-hadoop-config-YYYYMMDD.tar.gz` with configs, scripts, docs. Excludes logs, .git, tests.

| Usage | What It Does |
|-------|--------------|
| `./scripts/bundle-config.sh` | Creates tar.gz in project root |
| `./scripts/bundle-config.sh /path/to/dir` | Creates tar.gz in specified directory |

**Bundle contents:** docker-compose.yml, hadoop-conf/, spark-conf/, scripts/, docs/, jmx-exporter-config/, README.md, empty logs/ with .gitkeep, DEPLOY.md. Optional hive-conf/, hbase-conf/, pig-conf/ when present.

**On target host:** `tar -xzf spark-hadoop-config-*.tar.gz && cd spark-hadoop-config-* && ./scripts/fetch-hadoop-conf.sh && chmod 777 logs && docker compose up -d`

---

## scripts/sync-hdfs-logs-to-local.sh

Syncs YARN aggregated container logs from HDFS to a local directory so Azure Monitor Agent can collect them via a Custom Text Logs DCR.

| Environment | Default | Description |
|-------------|---------|--------------|
| `HDFS_LOG_DIR` | `/tmp/logs` | HDFS path for YARN log aggregation |
| `OUTPUT_DIR` | `/logs/hdfs-container-logs` | Local output directory |
| `HADOOP_CONF_DIR` | (required) | Hadoop config path |

**Usage:** `HADOOP_CONF_DIR=/path/to/hadoop-conf ./scripts/sync-hdfs-logs-to-local.sh`

**Production:** Run via cron or systemd timer. See [AZURE_MONITOR_HDFS_LOGS.md](AZURE_MONITOR_HDFS_LOGS.md).
