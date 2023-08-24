ARG DISTRO=alpine
ARG DISTRO_VARIANT=3.18

FROM docker.io/tiredofit/${DISTRO}:${DISTRO_VARIANT}
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

### Set Environment Variables
ENV INFLUX_VERSION=1.8.0 \
    INFLUX2_VERSION=2.4.0 \
    MSSQL_VERSION=18.0.1.1-1 \
    AWS_CLI_VERSION=1.25.97 \
    CONTAINER_ENABLE_MESSAGING=FALSE \
    CONTAINER_ENABLE_MONITORING=TRUE \
    CONTAINER_PROCESS_RUNAWAY_PROTECTOR=FALSE \
    IMAGE_NAME="tiredofit/db-backup" \
    IMAGE_REPO_URL="https://github.com/tiredofit/docker-db-backup/"

### Dependencies
RUN source /assets/functions/00-container && \
    set -ex && \
    package update && \
    package upgrade && \
    package install .db-backup-build-deps \
               build-base \
               bzip2-dev \
               cargo \
               git \
               go \
               libarchive-dev \
               openssl-dev \
               libffi-dev \
               python3-dev \
               py3-pip \
               xz-dev \
               && \
    \
    package install .db-backup-run-deps \
               bzip2 \
               groff \
               libarchive \
               mariadb-client \
               mariadb-connector-c \
               mongodb-tools \
               openssl \
               pigz \
               postgresql15 \
               postgresql15-client \
               pv \
               py3-botocore \
               py3-colorama \
               py3-cryptography \
               py3-docutils \
               py3-jmespath \
               py3-rsa \
               py3-setuptools \
               py3-s3transfer \
               py3-yaml \
               python3 \
               redis \
               sqlite \
               xz \
               zip \
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
    clone_git_repo https://github.com/aws/aws-cli "${AWS_CLI_VERSION}" && \
    python3 setup.py install --prefix=/usr && \
    clone_git_repo https://github.com/influxdata/influxdb "${INFLUX_VERSION}" && \
    go build -o /usr/sbin/influxd ./cmd/influxd && \
    strip /usr/sbin/influxd && \
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
    package remove .db-backup-build-deps && \
    package cleanup && \
    rm -rf \
            /*.apk \
            /etc/logrotate.d/* \
            /root/.cache \
            /root/go \
            /tmp/* \
            /usr/src/*


COPY install  /
