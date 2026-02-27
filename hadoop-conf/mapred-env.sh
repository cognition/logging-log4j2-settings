# Enable MapReduce JobHistory audit (uncomment when running MapReduce jobs)
# export MAPRED_HISTORYSERVER_OPTS="${MAPRED_HISTORYSERVER_OPTS:-} -Dmapreduce.hs.audit.logger=INFO"
export MAPRED_HISTORYSERVER_OPTS="-Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1030"
