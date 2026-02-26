# Spark Configuration — Line-by-Line Reference

Spark uses **Log4j 2** for logging. Each line is explained below. Reference: [Log4j 2 Configuration](https://logging.apache.org/log4j/2.x/manual/configuration.html), [Spark Configuration](https://spark.apache.org/docs/latest/configuration.html).

---

## spark-conf/log4j2.properties

| Line | Content | What It Does |
|------|---------|--------------|
| 1–4 | `#` comments | Header describing this file's purpose |
| 6 | `rootLogger.level = info` | Default log level for all loggers. `info` = normal operations, warnings, errors. Options: `trace`, `debug`, `info`, `warn`, `error`, `off` |
| 7 | `rootLogger.appenderRef.stdout.ref = console` | Root logger sends output to the appender named `console` |
| 9 | `appender.console.type = Console` | Defines an appender that writes to the console (stdout/stderr) |
| 10 | `appender.console.name = console` | Names this appender so other config can reference it |
| 11 | `appender.console.target = SYSTEM_ERR` | Writes to stderr (standard error). Use `SYSTEM_OUT` for stdout |
| 12 | `appender.console.layout.type = PatternLayout` | How each log line is formatted |
| 13 | `appender.console.layout.pattern = [${env:HOSTNAME:-unknown}] %d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n%ex` | Log format: `[hostname] date time level logger: message` + stack trace if present. `%ex` = exception. `:-unknown` = fallback if HOSTNAME not set |
| 15–16 | `# Spark application...` | Comment |
| 16 | `logger.spark.name = org.apache.spark` | Logger for Spark core classes |
| 17 | `logger.spark.level = info` | Log level for Spark |
| 19–20 | `logger.yarn.name/level` | Logger for YARN client code (who submits, resource allocation) |
| 23–24 | `appender.audit.type/name` | Rolling file appender for audit log |
| 25 | `appender.audit.fileName = /opt/spark/logs/spark-audit.log` | Current audit log file path (inside container) |
| 26 | `appender.audit.filePattern = /opt/spark/logs/spark-audit-%d{yyyy-MM-dd}.log` | Archived log filename pattern. Rolls daily |
| 27–28 | `appender.audit.layout.*` | Audit log format with `[Audit][Spark]` tag for SIEM |
| 29–31 | `appender.audit.policies.*` | Time-based rollover: new file every 1 day |
| 33–37 | `logger.audit.*` | Sends Spark logs to both console and audit file. `additivity = false` = don't also send to root logger (avoids duplicates) |
| 39–48 | `appender.access.*` | Rolling file for HTTP access logs (Spark History Server, driver UI). Path `/spark/logs` used by History Server container |
| 50–53 | `logger.access.*` | Captures Jetty HTTP request logs. `org.sparkproject.jetty.server.RequestLog` = web server request logger |
| 55–66 | `logger.repl/jetty1/jetty2/parquet1/parquet2` | Extra loggers at INFO for SIEM visibility (REPL, Jetty, Parquet) |

---

## spark-conf/spark-defaults.conf

Properties here apply to **all** Spark jobs submitted from this client. Reference: [Spark Configuration](https://spark.apache.org/docs/latest/configuration.html).

| Line | Content | What It Does |
|------|---------|--------------|
| 1–2 | `#` comments | Header |
| 4 | `spark.master yarn` | Run on YARN cluster (not local or standalone). Jobs are scheduled by YARN ResourceManager |
| 5 | `spark.submit.deployMode client` | Driver runs on the spark-client container (not inside YARN). Easier for debugging; use `cluster` for production long-running jobs |
| 6 | `spark.driver.host spark-client` | Hostname where the driver listens. Must match the spark-client container hostname |
| 7 | `spark.eventLog.enabled true` | Write event log (job history) to HDFS. Required for Spark History Server |
| 8 | `spark.eventLog.dir hdfs://namenode:8020/spark-history` | HDFS path for event logs. `namenode:8020` = NameNode RPC address |
| 9 | `spark.history.fs.logDirectory hdfs://namenode:8020/spark-history` | Where Spark History Server reads event logs from |
| 10 | `spark.yarn.historyServer.allowTracking true` | Allow running jobs to report their URL to YARN for "Tracking UI" link |
| 11 | `spark.yarn.historyServer.address sparkhistoryserver:18080` | Spark History Server URL. Used for "View in Spark UI" links |
| 13–14 | `# Prometheus...` | Comment |
| 14 | `spark.ui.prometheus.enabled true` | Expose Prometheus metrics at `/metrics/prometheus` on driver (4040) and History Server (18080) |

---

## spark-conf/metrics.properties

Configures Spark's built-in metrics system. Reference: [Spark Monitoring](https://spark.apache.org/docs/latest/monitoring.html).

| Line | Content | What It Does |
|------|---------|--------------|
| 1–5 | `#` comments | Header and endpoint locations |
| 7 | `*.sink.prometheusServlet.class=org.apache.spark.metrics.sink.PrometheusServlet` | Use Prometheus servlet for all metric sources |
| 8 | `*.sink.prometheusServlet.path=/metrics/prometheus` | URL path for Prometheus scrape |
| 9 | `master.sink.prometheusServlet.path=/metrics/master/prometheus` | Master metrics path (standalone mode; less relevant on YARN) |
| 10 | `applications.sink.prometheusServlet.path=/metrics/applications/prometheus` | Per-application metrics path |
