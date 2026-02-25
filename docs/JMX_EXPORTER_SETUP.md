# Adding Prometheus JMX Exporter to Hadoop

Hadoop does not include built-in Prometheus metrics. To expose Hadoop daemon metrics (NameNode, DataNode, ResourceManager, NodeManager, JobHistoryServer) for Prometheus scraping, use the **Prometheus JMX Exporter** as a Java agent.

This document describes the process. The configs are in `jmx-exporter-config/`. Implementation is left to the operator.

## Prerequisites

- Hadoop daemons running (VM or container)
- JMX already enabled on daemons (see `hdfs-env.sh`, `yarn-env.sh`, `mapred-env.sh`)

## Step 1: Download the JMX Exporter JAR

Download from [Prometheus JMX Exporter releases](https://github.com/prometheus/jmx_exporter/releases):

```bash
# Example: download to /opt/hadoop/jmx-exporter/
mkdir -p /opt/hadoop/jmx-exporter
curl -L -o /opt/hadoop/jmx-exporter/jmx_prometheus_javaagent.jar \
  https://github.com/prometheus/jmx_exporter/releases/download/parent-0.20.0/jmx_prometheus_javaagent-0.20.0.jar
```

Use the latest version from the releases page. The JAR must be on each host that runs a Hadoop daemon.

## Step 2: Deploy Config Files

Copy the YAML configs from `jmx-exporter-config/` to each host, e.g. `/opt/hadoop/jmx-exporter/`:

| Config File | Daemon |
|-------------|--------|
| `hadoop-namenode.yml` | NameNode |
| `hadoop-datanode.yml` | DataNode |
| `hadoop-resourcemanager.yml` | ResourceManager |
| `hadoop-nodemanager.yml` | NodeManager |
| `hadoop-jobhistory.yml` | JobHistoryServer |

## Step 3: Add Java Agent to Daemon Startup

Append the `-javaagent` option to each daemon's `*_OPTS` in the appropriate env file. Use distinct ports per daemon so Prometheus can scrape each.

### hdfs-env.sh

```bash
# NameNode - expose metrics on port 9090
export HDFS_NAMENODE_OPTS="${HDFS_NAMENODE_OPTS} -javaagent:/opt/hadoop/jmx-exporter/jmx_prometheus_javaagent.jar=9090:/opt/hadoop/jmx-exporter/hadoop-namenode.yml"

# DataNode - expose metrics on port 9091
export HDFS_DATANODE_OPTS="${HDFS_DATANODE_OPTS} -javaagent:/opt/hadoop/jmx-exporter/jmx_prometheus_javaagent.jar=9091:/opt/hadoop/jmx-exporter/hadoop-datanode.yml"
```

### yarn-env.sh

```bash
# ResourceManager - expose metrics on port 9092
export YARN_RESOURCEMANAGER_OPTS="${YARN_RESOURCEMANAGER_OPTS} -javaagent:/opt/hadoop/jmx-exporter/jmx_prometheus_javaagent.jar=9092:/opt/hadoop/jmx-exporter/hadoop-resourcemanager.yml"

# NodeManager - expose metrics on port 9093
export YARN_NODEMANAGER_OPTS="${YARN_NODEMANAGER_OPTS} -javaagent:/opt/hadoop/jmx-exporter/jmx_prometheus_javaagent.jar=9093:/opt/hadoop/jmx-exporter/hadoop-nodemanager.yml"
```

### mapred-env.sh

```bash
# JobHistoryServer - expose metrics on port 9094
export MAPRED_HISTORYSERVER_OPTS="${MAPRED_HISTORYSERVER_OPTS} -javaagent:/opt/hadoop/jmx-exporter/jmx_prometheus_javaagent.jar=9094:/opt/hadoop/jmx-exporter/hadoop-jobhistory.yml"
```

## Step 4: Restart Daemons

Restart each Hadoop daemon so the new `*_OPTS` take effect. The agent will expose metrics at `http://host:PORT/metrics`.

## Step 5: Configure Prometheus

Add scrape targets to `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'hadoop-namenode'
    static_configs:
      - targets: ['namenode-host:9090']
  - job_name: 'hadoop-datanode'
    static_configs:
      - targets: ['datanode-host:9091']
  - job_name: 'hadoop-resourcemanager'
    static_configs:
      - targets: ['resourcemanager-host:9092']
  - job_name: 'hadoop-nodemanager'
    static_configs:
      - targets: ['nodemanager-host:9093']
  - job_name: 'hadoop-jobhistory'
    static_configs:
      - targets: ['jobhistory-host:9094']
```

## Port Summary

| Daemon | JMX Port (existing) | Prometheus Metrics Port |
|--------|---------------------|-------------------------|
| NameNode | 1028 | 9090 |
| DataNode | 1029 | 9091 |
| ResourceManager | 1026 | 9092 |
| NodeManager | 1027 | 9093 |
| JobHistoryServer | 1030 | 9094 |

## Troubleshooting

- **Agent not loading:** Ensure the JAR path exists on the host and the daemon user can read it.
- **Port in use:** Change the port in the `-javaagent` argument (e.g. `9095` instead of `9090`).
- **No metrics:** Check `http://host:PORT/metrics` manually. Verify JMX is enabled on the daemon.
