# docker-compose.yml — Line-by-Line Reference

This file defines all containers for the Spark-on-YARN cluster. Reference: [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/).

---

## Top-Level

| Line | Content | What It Does |
|------|---------|--------------|
| 5 | `name: spark-hadoop` | Project name. Used for network/volume prefixes (e.g. `spark-hadoop_default`) |
| 7 | `services:` | Start of service definitions |

---

## namenode (HDFS NameNode)

| Line | Content | What It Does |
|------|---------|--------------|
| 8 | `namenode:` | Service name. Also used as hostname |
| 9 | `image: ghcr.io/hadoop-sandbox/hadoop-hdfs-namenode:latest` | Container image. NameNode manages HDFS metadata (file names, block locations) |
| 10–13 | `volumes:` | Mount host paths into container |
| 11 | `./hadoop-conf:/hadoop/etc/hadoop:ro` | Hadoop config. `:ro` = read-only |
| 12 | `./logs/namenode:/logs` | Per-node log directory (writable) |
| 13 | `namenode:/data` | Named volume for NameNode data (persists across restarts) |
| 14–16 | `environment:` | Environment variables |
| 15 | `LOG_DIR: /logs` | Where Hadoop writes logs |
| 16 | `HDFS_NAMENODE_OPTS: "-Dhdfs.audit.logger=INFO,RFAAUDIT -Dcom.sun.management.jmxremote=..."` | Java options: enable HDFS audit to RFAAUDIT appender; enable JMX on port 1028 for monitoring |
| 17 | `restart: always` | Restart container if it exits |
| 18 | `init: true` | Use init as PID 1 (proper signal handling) |
| 19 | `hostname: namenode` | Hostname inside container. Used in config (e.g. `fs.defaultFS`) |
| 20–24 | `healthcheck:` | Docker checks if service is ready |
| 21 | `test: ["CMD", "bash", "-c", "curl -f http://localhost:9870/ \|\| exit 1"]` | NameNode web UI on port 9870. `-f` = fail on HTTP error |
| 22 | `interval: 30s` | Check every 30 seconds |
| 23 | `timeout: 10s` | Fail if no response in 10s |
| 24 | `retries: 3` | 3 failures before "unhealthy" |
| 25 | `start_period: 2m` | Grace period before counting failures (NameNode starts slowly) |

---

## datanode (HDFS DataNode)

| Line | Content | What It Does |
|------|---------|--------------|
| 26–46 | `datanode:` | Stores actual HDFS blocks on disk |
| 31 | `hadoopnode:/data` | Shared volume with NodeManager (same host for co-location) |
| 32 | `dnsocket:/run/hadoop-hdfs` | Shared Unix socket for short-circuit reads (see hdfs-site.xml) |
| 36 | `ipc: shareable` | Allow other containers to share IPC namespace (NodeManager) |
| 38 | `hostname: hadoopnode` | Hostname. Different from service name |
| 39–41 | `depends_on: namenode: condition: service_healthy` | Wait for NameNode to be healthy before starting |
| 43 | `curl -f http://localhost:9864/` | DataNode web UI port |

---

## resourcemanager (YARN ResourceManager)

| Line | Content | What It Does |
|------|---------|--------------|
| 49–71 | `resourcemanager:` | YARN cluster manager. Schedules Spark/MapReduce jobs |
| 56 | `YARN_RESOURCEMANAGER_OPTS: "-Drm.audit.logger=INFO,RMAUDIT ..."` | Enable ResourceManager audit log; JMX on port 1026 |
| 70–71 | `ports: "8088:8088"` | Expose YARN UI to host. Access at `http://localhost:8088` |

---

## nodemanager (YARN NodeManager)

| Line | Content | What It Does |
|------|---------|--------------|
| 74–104 | `nodemanager:` | Runs Spark executors and MapReduce tasks on worker nodes |
| 75 | `image: ...hadoop-yarn-nodemanager-spark` | Image includes Spark libraries for executor support |
| 85 | `network_mode: service:datanode` | Share network with DataNode (same host) |
| 86 | `ipc: service:datanode` | Share IPC namespace (for short-circuit reads) |
| 87–91 | `security_opt: seccomp:unconfined`, `cap_add: SYS_ADMIN, SYSLOG` | Required for YARN container execution (running user jobs in containers) |
| 99 | `curl -f http://localhost:8042/` | NodeManager web UI |

---

## jobhistoryserver (MapReduce Job History)

| Line | Content | What It Does |
|------|---------|--------------|
| 105–129 | `jobhistoryserver:` | Stores and serves MapReduce job history |
| 128–129 | `ports: "19888:19888"` | Job History UI at `http://localhost:19888` |

---

## spark-history (Spark History Server)

| Line | Content | What It Does |
|------|---------|--------------|
| 131–161 | `spark-history:` | Serves Spark application history from HDFS event logs |
| 135–137 | `volumes:` | Spark config, logs, and Hadoop config (for HDFS client) |
| 136 | `./spark-conf:/spark/conf:ro` | Spark config (log4j2, spark-defaults, metrics) |
| 137 | `./logs:/logs` | Spark History Server logs |
| 138 | `./logs:/logs` | Shared for Jetty access logs |
| 142 | `HOSTNAME: sparkhistoryserver` | Used in log format `[sparkhistoryserver]` |
| 159–160 | `ports: "18080:18080"` | Spark History UI at `http://localhost:18080` |

---

## log-init (One-Time Log File Setup)

| Line | Content | What It Does |
|------|---------|--------------|
| 163–173 | `log-init:` | Runs once to create `rm-audit.log` with correct permissions |
| 166 | `busybox:latest` | Minimal image for simple file ops |
| 168 | `entrypoint: ["/bin/sh", "-c"]` | Override entrypoint |
| 166–171 | `log-init` command | Creates per-node directories (`logs/namenode/`, `logs/hadoopnode/`, etc.), sets permissions, and pre-creates `rm-audit.log` for ResourceManager |
| 172 | `restart: "no"` | Run once, don't restart |
| 171 | `depends_on: namenode: condition: service_healthy` | Wait for NameNode |

---

## bootstrap (HDFS Directory Setup)

| Line | Content | What It Does |
|------|---------|--------------|
| 175–191 | `bootstrap:` | One-time setup of HDFS directories |
| 179 | `user: hdfs` | Run as HDFS superuser |
| 183 | `command: "hdfs dfs -mkdir -p /spark-history /user/root /user/spark && hdfs dfs -chmod -R 777 ..."` | Create directories for Spark event logs and user home dirs. `chmod 777` for dev (not for production) |
| 190 | `restart: "no"` | Run once |

---

## spark-client (Job Submission Client)

| Line | Content | What It Does |
|------|---------|--------------|
| 193–222 | `spark-client:` | Container from which you run `spark-submit` |
| 194 | `image: apache/spark:3.5.6` | Official Spark image |
| 196–199 | `volumes:` | Spark config, Hadoop config (for YARN), logs |
| 197 | `./spark-conf:/opt/spark/conf` | Spark config (spark-defaults, log4j2, metrics) |
| 198 | `./hadoop-conf:/opt/spark/conf/hadoop:ro` | Hadoop config for YARN client |
| 204 | `command: ["sleep", "infinity"]` | Keep container running. You `docker exec` in to run spark-submit |
| 220–221 | `ports: "4040:4040"` | Spark driver UI (when a job is running) |

---

## networks and volumes

| Line | Content | What It Does |
|------|---------|--------------|
| 224–226 | `networks: default: name: spark-hadoop_default` | Custom network name |
| 228–231 | `volumes: dnsocket, hadoopnode, namenode` | Named volumes for persistent data |
