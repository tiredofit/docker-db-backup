FROM docker.io/tiredofit/alpine:3.16
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

### Set Environment Variables

ENV INFLUX2_VERSION=2.4.0 \
    MSSQL_VERSION=18.0.1.1-1 \
    CONTAINER_ENABLE_MESSAGING=FALSE \
    CONTAINER_ENABLE_MONITORING=TRUE \
    CONTAINER_PROCESS_RUNAWAY_PROTECTOR=FALSE \
    IMAGE_NAME="theraymy/db-backup" \
    IMAGE_REPO_URL="https://github.com/LeRaymy/docker-db-backup"

### Dependencies
RUN set -ex && \
    apk update && \
    apk upgrade && \
    apk add -t .db-backup-build-deps \
               build-base \
               bzip2-dev \
               git \
               libarchive-dev \
               libressl-dev \
               libffi-dev \
               python3-dev \
               py3-pip \
               xz-dev \
               && \
    \
    apk add --no-cache -t .db-backup-run-deps \
               aws-cli \
               bzip2 \
               influxdb \
               libarchive \
               mariadb-client \
               mariadb-connector-c \
               mongodb-tools \
               libressl \
               pigz \
               postgresql \
               postgresql-client \
               pv \
               py3-cryptography \
               redis \
               sqlite \
               xz \
               zstd \
               && \
    \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
    x86_64) mssql=true ; influx2=true ; influx_arch=amd64; ;; \
    aarch64 ) influx2=true ; influx_arch=arm64 ;; \
    *) sleep 0.1 ;; \
    esac; \
    \
    if [ $mssql = "true" ] ; then curl -O https://download.microsoft.com/download/b/9/f/b9f3cce4-3925-46d4-9f46-da08869c6486/msodbcsql18_${MSSQL_VERSION}_amd64.apk ; curl -O https://download.microsoft.com/download/b/9/f/b9f3cce4-3925-46d4-9f46-da08869c6486/mssql-tools18_${MSSQL_VERSION}_amd64.apk ; echo y | apk add --allow-untrusted msodbcsql18_${MSSQL_VERSION}_amd64.apk mssql-tools18_${MSSQL_VERSION}_amd64.apk ; else echo >&2 "Detected non x86_64 build variant, skipping MSSQL installation" ; fi; \
    if [ $influx2 = "true" ] ; then curl -sSL https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUX2_VERSION}-linux-${influx_arch}.tar.gz | tar xvfz - --strip=1 -C /usr/src/ ; chmod +x /usr/src/influx ; mv /usr/src/influx /usr/sbin/ ; else echo >&2 "Unable to build Influx 2 on this system" ; fi ; \
    \
    mkdir -p /usr/src/pbzip2 && \
    curl -sSL https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz | tar xvfz - --strip=1 -C /usr/src/pbzip2 && \
    cd /usr/src/pbzip2 && \
    make && \
    make install && \
    mkdir -p /usr/src/pixz && \
    curl -sSL https://github.com/vasi/pixz/releases/download/v1.0.7/pixz-1.0.7.tar.xz | tar xvfJ - --strip 1 -C /usr/src/pixz && \
    cd /usr/src/pixz && \
    ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    && \
    make && \
    make install && \
    \
    pip3 install blobxfer && \
    \
### Cleanup
    apk del .db-backup-build-deps && \
    rm -rf /usr/src/* && \
    rm -rf /*.apk && \
    rm -rf /etc/logrotate.d/redis && \
    rm -rf /root/.cache /tmp/* /var/cache/apk/*

### S6 Setup
ADD install  /
