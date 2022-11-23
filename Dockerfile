FROM docker.io/tiredofit/alpine:3.17
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

### Set Environment Variables
ENV INFLUX2_VERSION=2.4.0 \
    MSSQL_VERSION=18.0.1.1-1 \
    CONTAINER_ENABLE_MESSAGING=FALSE \
    CONTAINER_ENABLE_MONITORING=TRUE \
    CONTAINER_PROCESS_RUNAWAY_PROTECTOR=FALSE \
    IMAGE_NAME="tiredofit/db-backup" \
    IMAGE_REPO_URL="https://github.com/tiredofit/docker-db-backup/"

ENV LANG=en_US.utf8 \
    PG_MAJOR=15 \
    PG_VERSION=15.1 \
    PGDATA=/var/lib/postgresql/data

### Create User Accounts
RUN set -ex && \
    addgroup -g 70 postgres && \
    adduser -S -D -H -h /var/lib/postgresql -s /bin/sh -G postgres -u 70 postgres && \
    mkdir -p /var/lib/postgresql && \
    chown -R postgres:postgres /var/lib/postgresql && \
    \
### Install Dependencies
   apk update && \
   apk upgrade && \
   apk add \
       openssl \
       && \
   \
   apk add --no-cache --virtual .postgres-build-deps \
	   bison \
	   build-base \
	   coreutils \
	   dpkg-dev \
	   dpkg \
	   flex \
	   gcc \
	   icu-dev \
	   libc-dev \
   	   libedit-dev \
	   libxml2-dev \
	   libxslt-dev \
	   linux-headers \
	   make \
	   openssl-dev \
	   perl-utils \
	   perl-ipc-run \
	   util-linux-dev \
           wget \
	   zlib-dev \
       && \
   \
### Build Postgresql
   mkdir -p /usr/src/postgresql && \
   curl -sSL "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.bz2" | tar xvfj - --strip 1 -C /usr/src/postgresql && \
   cd /usr/src/postgresql && \
# update "DEFAULT_PGSOCKET_DIR" to "/var/run/postgresql" (matching Debian)
# see https://anonscm.debian.org/git/pkg-postgresql/postgresql.git/tree/debian/patches/51-default-sockets-in-var.patch?id=8b539fcb3e093a521c095e70bdfa76887217b89f
   awk '$1 == "#define" && $2 == "DEFAULT_PGSOCKET_DIR" && $3 == "\"/tmp\"" { $3 = "\"/var/run/postgresql\""; print; next } { print }' src/include/pg_config_manual.h > src/include/pg_config_manual.h.new && \
   grep '/var/run/postgresql' src/include/pg_config_manual.h.new && \
   mv src/include/pg_config_manual.h.new src/include/pg_config_manual.h && \
   gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
# explicitly update autoconf config.guess and config.sub so they support more arches/libcs
   wget --inet4-only -O config/config.guess 'https://git.savannah.gnu.org/cgit/config.git/plain/config.guess?id=7d3d27baf8107b630586c962c057e22149653deb' && \
   wget --inet4-only -O config/config.sub 'https://git.savannah.gnu.org/cgit/config.git/plain/config.sub?id=7d3d27baf8107b630586c962c057e22149653deb' && \
   ./configure \
		--build="$gnuArch" \
		--enable-integer-datetimes \
		--enable-thread-safety \
		--enable-tap-tests \
		--disable-rpath \
		--with-uuid=e2fs \
		--with-gnu-ld \
		--with-pgport=5432 \
		--with-system-tzdata=/usr/share/zoneinfo \
		--prefix=/usr/local \
		--with-includes=/usr/local/include \
		--with-libraries=/usr/local/lib \
		--with-openssl \
		--with-libxml \
		--with-libxslt \
		--with-icu \
	&& \
    \
    make -j "$(nproc)" world && \
    make install-world && \
    make -C contrib install && \
    runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" && \
	apk add -t .postgres-additional-deps \
	           $runDeps \
	           && \
	\
### Cleanup
    apk del .postgres-build-deps && \
    cd / && \
    rm -rf \
	/usr/src/postgresql \
	/usr/local/share/doc \
	/usr/local/share/man && \
    find /usr/local -name '*.a' -delete && \
    rm -rf /var/cache/apk/* && \
    \
### Dependencies
    set -ex && \
    apk update && \
    apk upgrade && \
    apk add -t .db-backup-build-deps \
               build-base \
               bzip2-dev \
               git \
               libarchive-dev \
               openssl-dev \
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
               openssl \
               pigz \
               #postgresql \
               #postgresql-client \
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
COPY install  /
