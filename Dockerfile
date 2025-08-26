ARG DISTRO=alpine
ARG DISTRO_VARIANT=3.21-7.10.28

FROM docker.io/tiredofit/${DISTRO}:${DISTRO_VARIANT}
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ENV INFLUX1_CLIENT_VERSION=1.8.0 \
    INFLUX2_CLIENT_VERSION=2.7.5 \
    MSODBC_VERSION=18.4.1.1-1 \
    MSSQL_VERSION=18.4.1.1-1 \
    DOTNET_VERSION=8.0.413 \
    SQLPACKAGE_VERSION=170.1.61 \
    MYSQL_VERSION=mysql-8.4.4 \
    MYSQL_REPO_URL=https://github.com/mysql/mysql-server \
    AWS_CLI_VERSION=1.36.40 \
    CONTAINER_ENABLE_MESSAGING=TRUE \
    CONTAINER_ENABLE_MONITORING=TRUE \
    IMAGE_NAME="tiredofit/db-backup" \
    IMAGE_REPO_URL="https://github.com/tiredofit/docker-db-backup/"

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
                    cmake \
                    git \
                    go \
                    libarchive-dev \
                    libtirpc-dev \
                    openssl-dev \
                    libffi-dev \
                    ncurses-dev \
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
                    libtirpc \
                    mariadb-client \
                    mariadb-connector-c \
                    mongodb-tools \
                    ncurses \
                    openssl \
                    pigz \
                    pixz \
                    postgresql17 \
                    postgresql17-client \
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
    case "$(uname -m)" in \
	    "x86_64" ) mssql=true ; mssql_arch=amd64; influx2=true ; influx_arch=amd64; ;; \
        "arm64" | "aarch64" ) mssql=true ; mssql_arch=arm64; influx2=true ; influx_arch=arm64 ;; \
        *) sleep 0.1 ;; \
    esac; \
    \
    if [ "${mssql,,}" = "true" ] ; then \
        curl -sSLO https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/msodbcsql18_${MSODBC_VERSION}_${mssql_arch}.apk ; \
        curl -sSLO https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/mssql-tools18_${MSSQL_VERSION}_${mssql_arch}.apk ; \
        echo y | apk add --allow-untrusted msodbcsql18_${MSODBC_VERSION}_${mssql_arch}.apk mssql-tools18_${MSSQL_VERSION}_${mssql_arch}.apk ; \
        # Install dotnet
        package install .db-backup-dotnet-deps \
            ca-certificates \
            krb5-libs \
            libgcc \
            libintl \
            libunwind \
            icu-libs \
            libssl3 \
            libstdc++ \
            zlib \
            && \
        curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --version ${DOTNET_VERSION}; \
        ln -s /root/.dotnet/ /usr/share/dotnet ; \
        # Install sqlpackage
        /root/.dotnet/dotnet tool install --global Microsoft.SqlPackage --version ${SQLPACKAGE_VERSION}; \
    else \
        echo >&2 "Detected non x86_64 or ARM64 build variant, skipping MSSQL installation" ; \
    fi; \
    \
    if [ "${influx2,,}" = "true" ] ; then \
        curl -sSL https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUX2_CLIENT_VERSION}-linux-${influx_arch}.tar.gz | tar xvfz - --strip=1 -C /usr/src/ ; \
        chmod +x /usr/src/influx ; \
        mv /usr/src/influx /usr/sbin/ ; \
    else \
        echo >&2 "Unable to build Influx 2 on this system" ; \
    fi ; \
    \
    clone_git_repo https://github.com/influxdata/influxdb "${INFLUX1_CLIENT_VERSION}" && \
    go build -o /usr/sbin/influxd ./cmd/influxd && \
    strip /usr/sbin/influxd && \
    \
    clone_git_repo "${MYSQL_REPO_URL}" "${MYSQL_VERSION}" && \
    cmake \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_INSTALL_PREFIX=/opt/mysql \
        -DFORCE_INSOURCE_BUILD=1 \
        -DWITHOUT_SERVER:BOOL=ON \
        && \
    make -j$(nproc) install && \
    \
    pip3 install --break-system-packages awscli==${AWS_CLI_VERSION} && \
    pip3 install --break-system-packages blobxfer && \
    \
    mkdir -p /usr/src/pbzip2 && \
    curl -sSL https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz | tar xvfz - --strip=1 -C /usr/src/pbzip2 && \
    cd /usr/src/pbzip2 && \
    make && \
    make install && \
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
