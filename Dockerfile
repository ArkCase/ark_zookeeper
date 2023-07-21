###########################################################################################################
#
# How to build:
#
# docker build -t arkcase/zookeeper:latest .
#
###########################################################################################################

ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG BASE_REPO="arkcase/base"
ARG BASE_TAG="8.7.0"
ARG ARCH="amd64"
ARG OS="linux"
ARG PKG="zookeeper"
ARG VER="3.8.1"
ARG BLD="03"
ARG SRC="http://archive.apache.org/dist/zookeeper/zookeeper-${VER}/apache-zookeeper-${VER}-bin.tar.gz"

FROM "${PUBLIC_REGISTRY}/${BASE_REPO}:${BASE_TAG}"

ARG ARCH
ARG OS
ARG PKG
ARG VER
ARG SRC
ARG APP_UID="2000"
ARG APP_GID="${APP_UID}"
ARG APP_USER="${PKG}"
ARG APP_GROUP="${APP_USER}"
ARG BASE_DIR="/app"
ARG HOME_DIR="${BASE_DIR}/${PKG}"
ARG DATA_DIR="${BASE_DIR}/data"
ARG LOGS_DIR="${BASE_DIR}/logs"
ARG CONF_DIR="${BASE_DIR}/conf"

RUN yum -y update && \
    yum -y install \
        java-11-openjdk-devel \
        lsof \
        sudo \
    && \
    yum -y clean all

LABEL ORG="ArkCase LLC" \
      MAINTAINER="Armedia Devops Team <devops@armedia.com>" \
      APP="zookeeper" \
      VERSION="${VER}" \
      IMAGE_SOURCE="https://github.com/ArkCase/ark_zookeeper"

ENV APP_UID="${APP_UID}" \
    APP_GID="${APP_GID}" \
    APP_USER="${APP_USER}" \
    APP_GROUP="${APP_GROUP}" \
    JAVA_HOME="/usr/lib/jvm/java" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    BASE_DIR="${BASE_DIR}" \
    DATA_DIR="${DATA_DIR}" \
    HOME_DIR="${HOME_DIR}" \
    LOGS_DIR="${LOGS_DIR}" \
    CONF_DIR="${CONF_DIR}" \
    ZOOCFGDIR="${CONF_DIR}" \
    ZOO_LOG_DIR="${LOGS_DIR}" \
    PATH="${HOME_DIR}/bin:${PATH}"

WORKDIR "${BASE_DIR}"

RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --create-home --home-dir "${HOME_DIR}" "${APP_USER}"

#################
# Build ZooKeeper
#################

RUN curl -o zookeeper.tar.gz "${SRC}" && \
    tar -xzvf zookeeper.tar.gz && \
    mv "apache-zookeeper-${VER}-bin"/* "${HOME_DIR}" && \
    rmdir "apache-zookeeper-${VER}-bin" && \
    rm -f zookeeper.tar.gz && \
    mkdir -p "${CONF_DIR}" "${DATA_DIR}" "${LOGS_DIR}" && \
    chown -R "${APP_USER}:${APP_GROUP}" "${HOME_DIR}" "${CONF_DIR}" "${DATA_DIR}" "${LOGS_DIR}" && \
    chmod -R u=rwX,g=rwX,o= "${HOME_DIR}" "${CONF_DIR}" "${DATA_DIR}" "${LOGS_DIR}"

COPY --chown=root:root entrypoint /
RUN chmod 755 /entrypoint

COPY --chown=root:root update-ssl /
COPY --chown=root:root 00-update-ssl /etc/sudoers.d
RUN chmod 0640 /etc/sudoers.d/00-update-ssl && \
    sed -i -e "s;\${ACM_GROUP};${APP_GROUP};g" /etc/sudoers.d/00-update-ssl

#################
# Configure Solr
#################

USER "${APP_USER}"
WORKDIR "${HOME_DIR}"

EXPOSE 8983

VOLUME [ "${CONF_DIR}" ]
VOLUME [ "${DATA_DIR}" ]
VOLUME [ "${LOGS_DIR}" ]

ENTRYPOINT [ "/entrypoint" ]
