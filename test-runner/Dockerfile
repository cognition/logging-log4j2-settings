# Test-runner image: Hadoop (hdfs), Hive (beeline), and Spark (spark-submit) CLIs
# to run the test suite against the stack. Not part of docker-compose; run standalone
# and attach to the stack network.
#
# Build:  docker build -t spark-hadoop-test-runner -f test-runner/Dockerfile .
# Run:    ./scripts/run-test-runner-container.sh  (or see that script for docker run)

FROM apache/spark:3.5.6 AS base

# Add Hadoop CLI (hdfs) and Hive (beeline) from official images
COPY --from=apache/hadoop:3.4 /opt/hadoop /opt/hadoop
COPY --from=apache/hive:4.0.0 /opt/hive /opt/hive

ENV HADOOP_HOME=/opt/hadoop \
    HIVE_HOME=/opt/hive \
    SPARK_HOME=/opt/spark

ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    SPARK_CONF_DIR=/opt/spark/conf

ENV PATH="${HADOOP_HOME}/bin:${HIVE_HOME}/bin:${SPARK_HOME}/bin:${PATH}"

# Default config dirs; override at run time by mounting hadoop-conf and spark-conf
RUN mkdir -p /opt/hadoop/etc/hadoop /opt/spark/conf

COPY run-tests.sh /run-tests.sh
RUN chmod +x /run-tests.sh

ENTRYPOINT ["/run-tests.sh"]
