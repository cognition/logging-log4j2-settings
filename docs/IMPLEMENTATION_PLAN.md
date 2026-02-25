# Requirements Logging Implementation Plan

This plan maps each requirement from [Requirements.md](../Requirements.md) to components and implementation steps, building on the existing logging infrastructure.

**Deployment context:** VM-style deployment. No Docker sidecars or container orchestration assumptions — each process exposes metrics and logs on its own host.

---

## Metrics Enablement for Prometheus (VM-Style, No Sidecars)

Enable metrics so Prometheus, Grafana, or other metrics servers can collect Hadoop and Spark metrics.

### Current State

- **Hadoop:** JMX is already enabled on all daemons via hdfs-env.sh, yarn-env.sh, mapred-env.sh (ports 1026–1030). hadoop-metrics2 FileSink is commented out.
- **Spark:** No metrics.properties; no Prometheus endpoint.

### Spark (Built-in Prometheus Support)

Spark 3.x includes `PrometheusServlet` that exposes metrics on existing HTTP ports.

**Action:**

- Create `spark-conf/metrics.properties` with PrometheusServlet sink
- Enable Prometheus metrics: `spark.ui.prometheus.enabled=true` in spark-defaults.conf

**Endpoints:** `http://host:18080/metrics/prometheus` (History Server), `http://host:4040/metrics/prometheus` (Driver)

### Hadoop (JMX Exporter as Java Agent — No Sidecars)

Hadoop has no built-in Prometheus sink. Use the **Prometheus JMX Exporter as a Java agent**. The agent runs inside each daemon's JVM and exposes an HTTP endpoint. Prometheus scrapes that port on the same host. No sidecars or extra processes.

**Action:**

1. Download `jmx_prometheus_javaagent-*.jar` and place it on each host (e.g. `/opt/hadoop/jmx-exporter/jmx_prometheus_javaagent.jar`).
2. Add YAML configs to `jmx-exporter-config/` (e.g. `hadoop-namenode.yml`, `hadoop-datanode.yml`) for each component.
3. Append `-javaagent:/path/to/jmx_prometheus_javaagent.jar=PORT:/path/to/config.yml` to each daemon's `*_OPTS` in hdfs-env.sh, yarn-env.sh, mapred-env.sh.
4. Use distinct ports per daemon (e.g. 9090 NameNode, 9091 DataNode, 9092 RM, 9093 NM, 9094 JHS).
5. Expose these ports in firewall/network config so Prometheus can scrape.

**Example for NameNode in hdfs-env.sh:**

```bash
export HDFS_NAMENODE_OPTS="-Dcom.sun.management.jmxremote=true ... -javaagent:/opt/hadoop/jmx-exporter/jmx_prometheus_javaagent.jar=9090:/opt/hadoop/jmx-exporter/hadoop-namenode.yml"
```

### Summary of Metrics Changes (VM-Style)

| Component            | Metrics Source    | Prometheus Endpoint | Port  |
| -------------------- | ----------------- | ------------------- | ----- |
| Spark History Server | PrometheusServlet | /metrics/prometheus | 18080 |
| Spark Driver         | PrometheusServlet | /metrics/prometheus | 4040  |
| NameNode             | JMX Exporter agent| /metrics            | 9090  |
| DataNode             | JMX Exporter agent| /metrics            | 9091  |
| ResourceManager      | JMX Exporter agent| /metrics            | 9092  |
| NodeManager          | JMX Exporter agent| /metrics            | 9093  |
| JobHistoryServer     | JMX Exporter agent| /metrics            | 9094  |

### File Changes for Metrics (No docker-compose Changes)

| File | Change |
|------|--------|
| `spark-conf/metrics.properties` (new) | PrometheusServlet sink configuration |
| spark-conf/spark-defaults.conf | Add `spark.ui.prometheus.enabled=true` |
| hadoop-conf/hdfs-env.sh | Add javaagent to HDFS_NAMENODE_OPTS, HDFS_DATANODE_OPTS |
| hadoop-conf/yarn-env.sh | Add javaagent to YARN_RESOURCEMANAGER_OPTS, YARN_NODEMANAGER_OPTS |
| hadoop-conf/mapred-env.sh | Add javaagent to MAPRED_HISTORYSERVER_OPTS |
| `jmx-exporter-config/` (new) | YAML configs for Hadoop components |
| hadoop-conf/hadoop-metrics2.properties | Enable FileSink for local metrics (optional) |
| README.md | Document metrics endpoints and Prometheus scrape config |

---

*Full plan with all requirements (logging, audit, retention, etc.) is in the Cursor plan. This doc captures the VM-style metrics approach.*
