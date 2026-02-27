# Enable MapReduce JobHistory audit (uncomment when running MapReduce jobs)
# export MAPRED_HISTORYSERVER_OPTS="${MAPRED_HISTORYSERVER_OPTS:-} -Dmapreduce.hs.audit.logger=INFO"
# -Dhadoop.root.logger=INFO,RFA routes logs to file (LOG_DIR) instead of console
export MAPRED_HISTORYSERVER_OPTS="-Dhadoop.root.logger=INFO,RFA -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1030"
