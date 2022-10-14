FROM redhat/ubi8

ARG kafka_version=3.2.0
ARG scala_version=2.13
ARG vcs_ref=unspecified
ARG build_date=unspecified

LABEL org.label-schema.name="kafka" \
      org.label-schema.description="Apache Kafka" \
      org.label-schema.build-date="${build_date}" \
      org.label-schema.vcs-url="https://github.com/wurstmeister/kafka-docker" \
      org.label-schema.vcs-ref="${vcs_ref}" \
      org.label-schema.version="${scala_version}_${kafka_version}" \
      org.label-schema.schema-version="1.0" \
      maintainer="wurstmeister"

ENV KAFKA_VERSION=$kafka_version \
    SCALA_VERSION=$scala_version \
    KAFKA_HOME=/opt/kafka

ENV PATH=${PATH}:${KAFKA_HOME}/bin

COPY download-kafka.sh start-kafka.sh broker-list.sh create-topics.sh versions.sh /tmp2/

RUN yum update ; \
    yum install -y jq wget java-17-openjdk-headless net-tools ; \
### BEGIN for CI tests
    yum install -y nmap-ncat  yum-utils ; \
## NB: Using centos as rhel only has s390x arch.
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo ; \
    yum makecache ; \
    yum install -y docker-ce-cli ; \
### END for CI tests
    chmod a+x /tmp2/*.sh ; \
    mv /tmp2/start-kafka.sh /tmp2/broker-list.sh /tmp2/create-topics.sh /tmp2/versions.sh /usr/bin ; \
    sync ; \
    /tmp2/download-kafka.sh ; \
    tar xfz /tmp2/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt ; \
    rm /tmp2/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz ; \
    ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME} ; \
    rm -rf /tmp2 ; \
    yum clean all ; \
    rm -rf /var/cache/yum

COPY overrides /opt/overrides

VOLUME ["/kafka"]

# Use "exec" form so that it runs as PID 1 (useful for graceful shutdown)
CMD ["start-kafka.sh"]
