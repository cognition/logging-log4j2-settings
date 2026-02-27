# Hadoop and Spark Logging Investigation

Apache Spark 3.5.6 on YARN (no Hive) with mounted conf and logs for practising logging configuration. Logs who submits jobs, what applications run, and main actions.

## Quick Start

```bash
# 1. Fetch Hadoop config from hadoop-sandbox (run once)
./scripts/fetch-hadoop-conf.sh

# 2. Ensure logs directory is writable
chmod 777 logs

# 3. Start YARN cluster + Spark client
docker compose up -d

# 4. Wait ~3–5 min for all services to be healthy, then submit a Spark job
./scripts/test-spark-yarn.sh
```

**Bundle for deployment:** Run `./scripts/bundle-config.sh` to create `spark-hadoop-config-YYYYMMDD.tar.gz` with configs, scripts, and docs. Extract on target host, run `fetch-hadoop-conf.sh`, then `docker compose up -d`.

**Migration from hadoop-logs/spark-logs:** If upgrading from an older layout, copy existing logs into `logs/` and remove the old directories.

If you see "Permission denied: user=spark" when submitting, create HDFS dirs once:
```bash
docker exec -u hdfs spark-hadoop-namenode-1 hdfs dfs -mkdir -p /user/spark /spark-history
docker exec -u hdfs spark-hadoop-namenode-1 hdfs dfs -chmod -R 777 /user /spark-history
```

## Documentation

**Documentation for system administrators:**
- [Configuration guide](docs/CONFIGURATION_GUIDE.md) — line-by-line config reference with glossary
- [Log scenarios](docs/LOG_SCENARIOS.md) — what happens and what you see in the logs (job submission, CRUD, startup, failures)

## Layout

| Path | Purpose |
|------|---------|
| `spark-conf/` | Mounted to `/opt/spark/conf` — log4j2.properties, spark-defaults.conf |
| `hadoop-conf/` | Mounted to `/hadoop/etc/hadoop` — YARN, HDFS config (from hadoop-sandbox). Uses Log4j 2 (`log4j2.properties`) |
| `logs/` | Mounted to `/logs` — **unified** log directory for all components (HDFS, YARN, Spark). Set via `LOG_DIR`. |
| `scripts/fetch-hadoop-conf.sh` | Fetches Hadoop config from hadoop-sandbox |
| `scripts/test-spark-yarn.sh` | Submits Spark Pi example to YARN |
| `scripts/bundle-config.sh` | Bundles configs into a tar for deployment to another system |

## Logging

- **Who submits:** YARN ResourceManager logs application submissions with user
- **What runs:** Spark driver logs job lifecycle; YARN logs application IDs
- **HDFS audit:** `hdfs.audit.logger=INFO,RFAAUDIT` in hadoop-conf/log4j2.properties
- **Spark audit:** logs/spark-audit.log — driver and application logs
- **UI access logs:** HTTP request logging for all web UIs (NCSA format):
  - logs/jetty-namenode.log, jetty-datanode.log, jetty-resourcemanager.log, jetty-jobhistory.log, jetty-nodemanager.log
  - logs/jetty-access.log (Spark History Server and driver UI)
- **Node identification:** All log lines include `[hostname]` prefix for SIEM correlation (e.g. `[namenode]`, `[resourcemanager]`, `[sparkhistoryserver]`)

## Metrics

- **Spark (built-in):** Prometheus metrics at `/metrics/prometheus` on driver (4040) and History Server (18080). Configured via `spark-conf/metrics.properties` and `spark.ui.prometheus.enabled=true`.
- **Hadoop JMX Exporter:** Configs in `jmx-exporter-config/`; process documented in [docs/JMX_EXPORTER_SETUP.md](docs/JMX_EXPORTER_SETUP.md). Not implemented by default.
- **hadoop-metrics2:** FileSink enabled; outputs to `logs/*-metrics.out` (namenode, datanode, resourcemanager, nodemanager, jobhistoryserver).

## Tests

Log verification tests ensure logging captures the right events per Requirements.md:

```bash
pip install -r requirements-test.txt
pytest tests/ -v
```

Requires the cluster to be running (`docker compose up -d`). See [tests/README.md](tests/README.md).

## Ports

- **8088** — YARN ResourceManager UI
- **18080** — Spark History Server
- **19888** — MapReduce Job History
- **9870** — HDFS NameNode (internal)
- **4040** — Spark driver UI (when a job is running)

## Components

- **ResourceManager** — YARN cluster manager
- **NodeManager** — YARN worker (runs Spark executors)
- **NameNode / DataNode** — HDFS (storage for YARN staging)
- **JobHistoryServer** — MapReduce history
- **Spark History Server** — Spark application history
- **spark-client** — apache/spark:3.5.6 for submitting jobs
