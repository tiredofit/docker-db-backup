FROM tiredofit/alpine:edge

### Set Environment Variables
ENV MSSQL_VERSION=17.5.2.1-1 \
    ENABLE_CRON=FALSE \
    ENABLE_SMTP=FALSE \
    ENABLE_ZABBIX=TRUE \
    ZABBIX_HOSTNAME=db-backup

ENV LANG=en_US.utf8 \
    PG_MAJOR=13 \
    PG_VERSION=13.0 \
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
   wget -O config/config.guess 'https://git.savannah.gnu.org/cgit/config.git/plain/config.guess?id=7d3d27baf8107b630586c962c057e22149653deb' && \
   wget -O config/config.sub 'https://git.savannah.gnu.org/cgit/config.git/plain/config.sub?id=7d3d27baf8107b630586c962c057e22149653deb' && \
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
    echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add -t .db-backup-build-deps \
               build-base \
               bzip2-dev \
               git \
               xz-dev \
               && \
    \
    apk add --no-cache -t .db-backup-run-deps \
      	       bzip2 \
               influxdb \
               mariadb-client \
               mongodb-tools \
               libressl \
               pigz \
               #postgresql \
               #postgresql-client \
               redis \
               xz \
               zstd \
               && \
    \
    apk add --no-cache \
               pixz@testing \
               && \
    \
    cd /usr/src && \
    curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_${MSSQL_VERSION}_amd64.apk && \
    curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_${MSSQL_VERSION}_amd64.apk && \
    echo y | apk add --allow-untrusted msodbcsql17_${MSSQL_VERSION}_amd64.apk mssql-tools_${MSSQL_VERSION}_amd64.apk && \
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
    rm -rf /tmp/* /var/cache/apk/* && \
    \
### Temp Hack for S6 Overlay && \
### S6 installation
    apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		x86_64) s6Arch='amd64' ;; \
		armhf) s6Arch='armhf' ;; \
		aarch64) s6Arch='aarch64' ;; \
		ppc64le) s6Arch='ppc64le' ;; \
		*) echo >&2 "Error: unsupported architecture ($apkArch)"; exit 1 ;; \
	esac; \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${s6Arch}.tar.gz | tar xfz - -C /

### S6 Setup
    ADD install  /
