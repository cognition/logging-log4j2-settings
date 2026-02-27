# Enable HDFS audit logging for SIEM (overrides log4j default NullAppender)
export HDFS_AUDIT_LOGGER=INFO,RFAAUDIT

# -Dhadoop.root.logger=INFO,RFA routes logs to file (LOG_DIR) instead of console
export HDFS_NAMENODE_OPTS="-Dhadoop.root.logger=INFO,RFA -Dhdfs.audit.logger=INFO,RFAAUDIT -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1028"
export HDFS_DATANODE_OPTS="-Dhadoop.root.logger=INFO,RFA -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1029"
