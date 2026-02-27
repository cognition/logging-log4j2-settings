# MapReduce-specific logging and JMX configuration

# JobHistoryServer: file logging, audit logger, JMX
export MAPRED_HISTORYSERVER_OPTS="${MAPRED_HISTORYSERVER_OPTS:-} -Dhadoop.root.logger=INFO,RFA -Dmapreduce.hs.audit.logger=INFO -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1030"

