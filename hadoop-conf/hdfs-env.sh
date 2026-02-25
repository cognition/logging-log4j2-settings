# Enable HDFS audit logging for SIEM (overrides log4j default NullAppender)
export HDFS_AUDIT_LOGGER=INFO,RFAAUDIT

export HDFS_NAMENODE_OPTS="-Dhdfs.audit.logger=INFO,RFAAUDIT -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1028"
export HDFS_DATANODE_OPTS="-Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1029"
