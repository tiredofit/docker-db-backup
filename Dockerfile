FROM tiredofit/mongo-builder as mongo-packages

FROM tiredofit/alpine:edge
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Copy Mongo Packages
COPY --from=mongo-packages / /usr/src/apk

### Set Environment Variables
   ENV ENABLE_CRON=FALSE \
       ENABLE_SMTP=FALSE

### Dependencies
   RUN set -ex && \
       echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
       apk update && \
       apk upgrade && \
       apk add --virtual .db-backup-build-deps \
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
           libressl \
           pigz \
           postgresql \
           postgresql-client \
           redis \
           xz \
           && \
       apk add \
           pixz@testing \
           && \
       \        
       ## Locally Install Mongo Package
       cd /usr/src/apk && \
       apk add -t .db-backup-mongo-deps --allow-untrusted \
           mongodb-tools*.apk \
           && \
       \
       cd /usr/src && \
       mkdir -p pbzip2 && \
       curl -ssL https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz | tar xvfz - --strip=1 -C /usr/src/pbzip2 && \
       cd pbzip2 && \
       make && \
       make install && \
       \
### Cleanup
       rm -rf /usr/src/* && \
       apk del .db-backup-build-deps && \
       rm -rf /tmp/* /var/cache/apk/*

### S6 Setup
    ADD install  /
