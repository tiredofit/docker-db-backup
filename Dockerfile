FROM tiredofit/alpine:3.14

### Set Environment Variables
ENV MSSQL_VERSION=17.5.2.1-1 \
    ENABLE_CRON=FALSE \
    ENABLE_SMTP=FALSE \
    ENABLE_ZABBIX=TRUE \
    ZABBIX_HOSTNAME=db-backup

    ### Dependencies
RUN set -ex && \
    apk update && \
    apk upgrade && \
    apk add -t .db-backup-build-deps \
               build-base \
               bzip2-dev \
               git \
               libarchive-dev \
               py3-pip \
               xz-dev \
               && \
    \
    apk add --no-cache -t .db-backup-run-deps \
      	       bzip2 \
               influxdb \
               libarchive \
               mariadb-client \
               mongodb-tools \
               libressl \
               pigz \
               postgresql \
               postgresql-client \
               python3 \
               redis \
               sqlite \
               xz \
               zstd \
               && \
    \
    cd /usr/src && \
    \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
	x86_64) mssql=true ; curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_${MSSQL_VERSION}_amd64.apk ; curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_${MSSQL_VERSION}_amd64.apk ; echo y | apk add --allow-untrusted msodbcsql17_${MSSQL_VERSION}_amd64.apk mssql-tools_${MSSQL_VERSION}_amd64.apk ;; \
	*) echo >&2 "Detected non x86_64 build variant, skipping MSSQL installation" ;; \
    esac; \
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
    pip3 install --upgrade pip && \
    pip3 install awscli && \
    \	
### Cleanup
    apk del .db-backup-build-deps && \
    rm -rf /usr/src/* && \
    rm -rf /root/.cache /tmp/* /var/cache/apk/*

### S6 Setup
    ADD install  /
