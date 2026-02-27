# Generic Hadoop environment configuration for logging-focused cluster

# Use English locale for consistent logs
export LANG=en_US.UTF-8

# Standardised log directory. LOG_DIR is canonical; all daemons honour it.
# On Docker: /logs (mounted from ./logs); on VM: set LOG_DIR before starting services.
export LOG_DIR="${LOG_DIR:-${HADOOP_LOG_DIR:-${HADOOP_HOME:-/hadoop}/logs}}"
export HADOOP_LOG_DIR="${LOG_DIR}"

# Hostname for SIEM/log correlation. Allow LOG_TAG_HOSTNAME override, else system hostname.
export HADOOP_OPTS="${HADOOP_OPTS:-} -Dlog4j.hostname=${LOG_TAG_HOSTNAME:-$(hostname)}"

# Default daemon root logger: send to file appender (RFA) by default.
export HADOOP_DAEMON_ROOT_LOGGER=INFO,RFA

