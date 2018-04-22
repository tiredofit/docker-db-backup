FROM registry.selfdesign.org/docker/alpine:edge
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Set Environment Variables
   ENV ENABLE_CRON=FALSE \
       ENABLE_SMTP=FALSE

### Dependencies
   RUN set -ex ; \
       echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories ; \
       apk update ; \
       apk upgrade ; \
       apk add --virtual .db-backup-build-deps \
           build-base \
           bzip2-dev \
           git \
           xz-dev \
           ; \
           \
       apk add --virtual .db-backup-run-deps  \
       	   bzip2 \
           mongodb-tools \
           mariadb-client \
           openssl \
           pigz \
           postgresql \
           postgresql-client \
           redis \
           xz \
           ; \
        apk add \
            influxdb@testing \
            pixz@testing \
           ; \
          \
          cd /usr/src ; \
          mkdir -p pbzip2 ; \
          curl -ssL https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz | tar xvfz - --strip=1 -C /usr/src/pbzip2 ; \
          cd pbzip2 ; \
          make ; \
          make install ; \
          \
          # Cleanup
          rm -rf /usr/src/* ; \
          apk del .db-backup-build-deps ; \
          rm -rf /tmp/* /var/cache/apk/*

### S6 Setup
    ADD install  /
