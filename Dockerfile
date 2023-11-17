ARG DISTRO=alpine
ARG DISTRO_VARIANT=edge

FROM docker.io/tiredofit/${DISTRO}:${DISTRO_VARIANT}
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

### Set Environment Variables
ENV INFLUX1_CLIENT_VERSION=1.8.0 \
    INFLUX2_CLIENT_VERSION=2.7.3 \
    MSODBC_VERSION=18.3.2.1-1 \
    MSSQL_VERSION=18.3.1.1-1 \
    AWS_CLI_VERSION=1.29.78 \
    CONTAINER_ENABLE_MESSAGING=TRUE \
    CONTAINER_ENABLE_MONITORING=TRUE \
    IMAGE_NAME="tiredofit/db-backup" \
    IMAGE_REPO_URL="https://github.com/tiredofit/docker-db-backup/"

### Dependencies
RUN source /assets/functions/00-container && \
    set -ex && \
    addgroup -S -g 10000 dbbackup && \
    adduser -S -D -H -u 10000 -G dbbackup -g "Tired of I.T! DB Backup" dbbackup && \
    \
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
                    coreutils \
                    gpg \
                    gpg-agent \
                    groff \
                    libarchive \
                    mariadb-client \
                    mariadb-connector-c \
                    mongodb-tools \
                    openssl \
                    pigz \
                    postgresql16 \
                    postgresql16-client \
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
    apkArch="$(uname -m)"; \
    case "$apkArch" in \
	x86_64) mssql=true ; mssql_arch=amd64; influx2=true ; influx_arch=amd64; ;; \
        arm64 ) mssql=true ; mssql_arch=amd64; influx2=true ; influx_arch=arm64 ;; \
        *) sleep 0.1 ;; \
    esac; \
    \
    if [ $mssql = "true" ] ; then curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_${MSODBC_VERSION}_${mssql_arch}.apk ; curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/mssql-tools18_${MSSQL_VERSION}_${mssql_arch}.apk ; ls -l ; echo y | apk add --allow-untrusted msodbcsql18_${MSODBC_VERSION}_${mssql_arch}.apk mssql-tools18_${MSSQL_VERSION}_${mssql_arch}.apk ; else echo >&2 "Detected non x86_64 or ARM64 build variant, skipping MSSQL installation" ; fi; \
    if [ $influx2 = "true" ] ; then curl -sSL https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUX2_CLIENT_VERSION}-linux-${influx_arch}.tar.gz | tar xvfz - --strip=1 -C /usr/src/ ; chmod +x /usr/src/influx ; mv /usr/src/influx /usr/sbin/ ; else echo >&2 "Unable to build Influx 2 on this system" ; fi ; \
    clone_git_repo https://github.com/aws/aws-cli "${AWS_CLI_VERSION}" && \
    python3 setup.py install --prefix=/usr && \
    clone_git_repo https://github.com/influxdata/influxdb "${INFLUX1_CLIENT_VERSION}" && \
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
    pip3 install --break-system-packages blobxfer && \
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
