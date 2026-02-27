# Spark-Hadoop Logging Project

Apache Spark 3.5.6 on YARN with configurable logging for practising and demonstrating Hadoop ecosystem logging. Unified log directory, audit logs, UI access logs, and optional syslog forwarding.

**Full documentation:** [docs/PROJECT.md](docs/PROJECT.md)

---

## What It Does

- **Docker Compose cluster** — HDFS, YARN, MapReduce, Spark History Server, Spark client
- **Unified logging** — All components write to `logs/` via `LOG_DIR`
- **Audit logs** — HDFS operations, YARN submissions, Spark job lifecycle
- **UI access logs** — HTTP request logging for all web UIs
- **Syslog variants** — Optional configs to forward logs to syslog
- **Deployment** — Bundle configs; Ansible role for automation

---

## Dependencies

| Type | Requirement |
|------|-------------|
| **Required** | Docker 20.10+, Docker Compose v2+, Git, Bash |
| **Testing** | Python 3.12 (or 3.6+), pytest ≥5.0 |
| **Optional** | Ansible 2.9+ (for deploy-logging playbook) |

Container images are pulled automatically from hadoop-sandbox and Docker Hub.

---

## Quick Start

```bash
# 1. Fetch Hadoop config (run once)
./scripts/fetch-hadoop-conf.sh

# 2. Prepare logs directory
chmod 777 logs

# 3. Start cluster
docker compose up -d

# 4. Wait ~3–5 min, then submit a Spark job
./scripts/test-spark-yarn.sh
```

---

## Usage

| Task | Command |
|------|---------|
| **Bundle for deployment** | `./scripts/bundle-config.sh` |
| **Run tests** | `pip install -r requirements-test.txt && pytest tests/ -v` (cluster must be running) |
| **Ansible deploy** | `ansible-playbook -i localhost, -c local ansible/playbooks/deploy-logging.yml` |

---

## Documentation

| Document | Contents |
|----------|----------|
| [PROJECT.md](docs/PROJECT.md) | **Full project docs** — overview, dependencies, usage, references |
| [CONFIGURATION_GUIDE.md](docs/CONFIGURATION_GUIDE.md) | Config reference, glossary |
| [LOGGING_TOGGLES.md](docs/LOGGING_TOGGLES.md) | Per-component toggles |
| [SYSLOG_SETUP.md](docs/SYSLOG_SETUP.md) | Syslog configuration |
| [LOG_SCENARIOS.md](docs/LOG_SCENARIOS.md) | What you see in the logs |
| [ANSIBLE.md](docs/ANSIBLE.md) | Ansible role and module |

---

## Layout

| Path | Purpose |
|------|---------|
| `hadoop-conf/` | Hadoop config (HDFS, YARN, MapReduce) |
| `spark-conf/` | Spark config (log4j2, spark-defaults, metrics) |
| `logs/` | Unified log directory |
| `scripts/` | fetch-hadoop-conf.sh, test-spark-yarn.sh, bundle-config.sh |
| `ansible/` | Role, playbook, hadoop_logging_toggle module |
| `docs/` | Documentation |
| `tests/` | Log verification tests |

---

## Ports

- **8088** — YARN ResourceManager UI
- **18080** — Spark History Server
- **19888** — MapReduce Job History
- **4040** — Spark driver UI (when job runs)

---

## References

- [Apache Spark](https://spark.apache.org/) · [Hadoop](https://hadoop.apache.org/) · [hadoop-sandbox](https://github.com/hadoop-sandbox/hadoop-sandbox) · [Log4j 2](https://logging.apache.org/log4j/2.x/)

---

## Troubleshooting

**Permission denied: user=spark**

```bash
docker exec -u hdfs spark-hadoop-namenode-1 hdfs dfs -mkdir -p /user/spark /spark-history
docker exec -u hdfs spark-hadoop-namenode-1 hdfs dfs -chmod -R 777 /user /spark-history
```
