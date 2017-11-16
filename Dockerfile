FROM tiredofit/alpine:edge
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Set Environment Variables
   ENV ENABLE_CRON=FALSE \
       ENABLE_SMTP=FALSE

### Dependencies
   RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
       apk update && \
       apk add \
       	   bzip2 \
           influxdb@testing \
           mongodb-tools \
       	   mysql-client \
       	   postgresql \
           postgresql-client \
           openssl \
           redis \
    	   xz \
           && \

       rm -rf /var/cache/apk/* 


### S6 Setup
   ADD install  /

### Entrypoint Configuration  
   ENTRYPOINT ["/init"]

