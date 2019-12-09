FROM tiredofit/alpine:edge
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Set Environment Variables
ENV ENABLE_CRON=FALSE \
    ENABLE_SMTP=FALSE \
    ENABLE_ZABBIX=FALSE \
    ZABBIX_HOSTNAME=db-backup

### Dependencies
RUN set -ex && \
    echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add -t .db-backup-build-deps \
               build-base \
               bzip2-dev \
               git \
               xz-dev \
               && \
    \
    apk add -t .db-backup-run-deps \
      	       bzip2 \
               influxdb \
               mariadb-client \
               mongodb-tools \
               libressl \
               pigz \
               postgresql \
               postgresql-client \
               redis \
               xz \
               && \
    \
    apk add \
            pixz@testing \
            && \
    \        
    mkdir -p /usr/src/pbzip2 && \
    curl -ssL https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz | tar xvfz - --strip=1 -C /usr/src/pbzip2 && \
    cd /usr/src/pbzip2 && \
    make && \
    make install && \
    \
### Cleanup
    apk del .db-backup-build-deps && \
    rm -rf /usr/src/* && \
    rm -rf /tmp/* /var/cache/apk/*

### S6 Setup
    ADD install  /
