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
       	   openssl \
           redis \
    	   xz \
           && \

### Build Postgres 10
       mkdir -p /usr/src/postgresql && \
       curl https://ftp.postgresql.org/pub/source/v10.0/postgresql-10.0.tar.bz2 | tar xvfj - --strip 1 -C /usr/src/postgresql && \
 
       apk add --no-cache --virtual .build-deps \
		bison \
		coreutils \
		dpkg-dev dpkg \
		flex \
		gcc \
		libc-dev \
		libedit-dev \
		libxml2-dev \
		libxslt-dev \
		make \
		openssl-dev \
		perl-utils \
		perl-ipc-run \
		util-linux-dev \
		zlib-dev \
	        && \
       cd /usr/src/postgresql && \
       awk '$1 == "#define" && $2 == "DEFAULT_PGSOCKET_DIR" && $3 == "\"/tmp\"" { $3 = "\"/var/run/postgresql\""; print; next } { print }' src/include/pg_config_manual.h > src/include/pg_config_manual.h.new && \ 
       grep '/var/run/postgresql' src/include/pg_config_manual.h.new && \
       mv src/include/pg_config_manual.h.new src/include/pg_config_manual.h && \
       gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
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
		\
		--with-openssl \
		--with-libxml \
		--with-libxslt && \
       make -j "$(nproc)" world && \
       make install-world && \
       make -C contrib install && \
	\
       apk del .build-deps && \
       cd / && \
       rm -rf \
        	/usr/src/postgresql \
		/usr/local/share/doc \
		/usr/local/share/man && \
       find /usr/local -name '*.a' -delete && \
       rm -rf /var/cache/apk/* 


### S6 Setup
   ADD install  /

### Entrypoint Configuration  
   ENTRYPOINT ["/init"]

