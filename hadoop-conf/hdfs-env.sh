# HDFS-specific logging and JMX configuration

# Enable HDFS audit logging for SIEM (overrides default NullAppender)
export HDFS_AUDIT_LOGGER=INFO,RFAAUDIT

# NameNode JVM options: file logging, audit logger, metrics, JMX
export HDFS_NAMENODE_OPTS="${HDFS_NAMENODE_OPTS:-} -Dhadoop.root.logger=INFO,RFA -Dhdfs.audit.logger=INFO,RFAAUDIT -Dnamenode.metrics.logger=INFO -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1028"

# DataNode JVM options: file logging, metrics, JMX
export HDFS_DATANODE_OPTS="${HDFS_DATANODE_OPTS:-} -Dhadoop.root.logger=INFO,RFA -Ddatanode.metrics.logger=INFO -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1029"

