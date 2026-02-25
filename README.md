# Hadoop and Spark Logging Investigation

Apache Spark 3.5.6 on YARN (no Hive) with mounted conf and logs for practising logging configuration. Logs who submits jobs, what applications run, and main actions.

## Quick Start

```bash
# 1. Fetch Hadoop config from hadoop-sandbox (run once)
./scripts/fetch-hadoop-conf.sh

# 2. Ensure logs directories are writable
chmod 777 spark-logs hadoop-logs

# 3. Start YARN cluster + Spark client
docker compose up -d

# 4. Wait ~3–5 min for all services to be healthy, then submit a Spark job
./scripts/test-spark-yarn.sh
```

If you see "Permission denied: user=spark" when submitting, create HDFS dirs once:
```bash
docker exec -u hdfs spark-hadoop-namenode-1 hdfs dfs -mkdir -p /user/spark /spark-history
docker exec -u hdfs spark-hadoop-namenode-1 hdfs dfs -chmod -R 777 /user /spark-history
```

## Layout

| Path | Purpose |
|------|---------|
| `spark-conf/` | Mounted to `/opt/spark/conf` — log4j2.properties, spark-defaults.conf |
| `spark-logs/` | Mounted to `/opt/spark/logs` — Spark driver/executor logs |
| `hadoop-conf/` | Mounted to `/hadoop/etc/hadoop` — YARN, HDFS config (from hadoop-sandbox) |
| `hadoop-logs/` | Mounted to `/hadoop/logs` — YARN, HDFS logs |
| `scripts/fetch-hadoop-conf.sh` | Fetches Hadoop config from hadoop-sandbox |
| `scripts/test-spark-yarn.sh` | Submits Spark Pi example to YARN |

## Logging

- **Who submits:** YARN ResourceManager logs application submissions with user
- **What runs:** Spark driver logs job lifecycle; YARN logs application IDs
- **HDFS audit:** `hdfs.audit.logger=INFO,RFAAUDIT` in hadoop-conf/log4j.properties
- **Spark audit:** spark-logs/spark-audit.log — driver and application logs

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
