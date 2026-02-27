# Use RFA (file) instead of console so logs write to LOG_DIR
export YARN_ROOT_LOGGER=INFO,RFA

# -Dyarn.root.logger=INFO,RFA and -Dhadoop.root.logger=INFO,RFA route logs to file instead of console
export YARN_RESOURCEMANAGER_OPTS="-Dyarn.root.logger=INFO,RFA -Dhadoop.root.logger=INFO,RFA -Drm.audit.logger=INFO,RMAUDIT -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1026"
export YARN_NODEMANAGER_OPTS="-Dyarn.root.logger=INFO,RFA -Dhadoop.root.logger=INFO,RFA -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1027"
