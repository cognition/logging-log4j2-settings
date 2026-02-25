# JMX Exporter Configs for Hadoop

Config files for the [Prometheus JMX Exporter](https://github.com/prometheus/jmx_exporter) Java agent. Used when adding Prometheus metrics to Hadoop daemons.

**Not implemented by default.** See [docs/JMX_EXPORTER_SETUP.md](../docs/JMX_EXPORTER_SETUP.md) for the full process.

| Config | Daemon |
|--------|--------|
| hadoop-namenode.yml | NameNode |
| hadoop-datanode.yml | DataNode |
| hadoop-resourcemanager.yml | ResourceManager |
| hadoop-nodemanager.yml | NodeManager |
| hadoop-jobhistory.yml | JobHistoryServer |
