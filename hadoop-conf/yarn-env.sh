# YARN-specific logging and JMX configuration

# Root logger for YARN daemons: file appender (RFA)
export YARN_ROOT_LOGGER=INFO,RFA

# ResourceManager: file logging, audit logger, JMX
export YARN_RESOURCEMANAGER_OPTS="${YARN_RESOURCEMANAGER_OPTS:-} -Dyarn.root.logger=INFO,RFA -Dhadoop.root.logger=INFO,RFA -Drm.audit.logger=INFO,RMAUDIT -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1026"

# NodeManager: file logging, NM audit logger, MapReduce shuffle audit, JMX
export YARN_NODEMANAGER_OPTS="${YARN_NODEMANAGER_OPTS:-} -Dyarn.root.logger=INFO,RFA -Dhadoop.root.logger=INFO,RFA -Dnm.audit.logger=INFO -Dmapreduce.shuffle.audit.logger=INFO -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1027"

