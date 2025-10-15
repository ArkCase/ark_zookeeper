###########################################################################################################
#
# How to build:
#
# docker build -t arkcase/zookeeper:latest .
#
###########################################################################################################

ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG ARCH="amd64"
ARG OS="linux"
ARG PKG="zookeeper"
ARG VER="3.8.5"
ARG JAVA="11"
ARG KEYS="https://downloads.apache.org/zookeeper/KEYS"
ARG SRC="https://archive.apache.org/dist/zookeeper/zookeeper-${VER}/apache-zookeeper-${VER}-bin.tar.gz"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base-java"
ARG BASE_VER="22.04"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}:${BASE_VER_PFX}${BASE_VER}"

FROM "${BASE_IMG}"

ARG ARCH
ARG OS
ARG PKG
ARG VER
ARG JAVA
ARG KEYS
ARG SRC
ARG APP_UID="2000"
ARG APP_GID="${APP_UID}"
ARG APP_USER="${PKG}"
ARG APP_GROUP="${APP_USER}"

LABEL ORG="ArkCase LLC" \
      MAINTAINER="Armedia Devops Team <devops@armedia.com>" \
      APP="zookeeper" \
      VERSION="${VER}" \
      IMAGE_SOURCE="https://github.com/ArkCase/ark_zookeeper"

ENV APP_UID="${APP_UID}" \
    APP_GID="${APP_GID}" \
    APP_USER="${APP_USER}" \
    APP_GROUP="${APP_GROUP}"
ENV HOME_DIR="${BASE_DIR}/${PKG}"
ENV ZOOCFGDIR="${CONF_DIR}" \
    ZOO_LOG_DIR="${LOGS_DIR}"
ENV PATH="${HOME_DIR}/bin:${PATH}"

RUN set-java "${JAVA}" && \
    apt-get -y install \
        lsof \
      && \
    apt-get clean

RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --group "${ACM_GROUP}" --create-home --home-dir "${HOME_DIR}" "${APP_USER}"

RUN verified-download --keys "${KEYS}" "${SRC}" "/zookeeper.tar.gz" && \
    tar -C "${HOME_DIR}" --strip-components=1 -xzvf "/zookeeper.tar.gz" && \
    rm -f "/zookeeper.tar.gz" && \
    mkdir -p "${CONF_DIR}" "${DATA_DIR}" "${LOGS_DIR}"

COPY --chown=root:root --chmod=0755 entrypoint /

COPY --chown=root:root --chmod=0755 render-peer-list /usr/local/bin

COPY --chown=root:root --chmod=0755 CVE /CVE
RUN apply-fixes /CVE

RUN rm -rf /tmp/* && \
    chown -R "${APP_USER}:${APP_GROUP}" "${BASE_DIR}" && \
    chmod -R u=rwX,g=rX,o= "${BASE_DIR}"

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
