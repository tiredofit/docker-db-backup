# hub.docker.com/r/tiredofit/db-backup


[![Build Status](https://img.shields.io/docker/build/tiredofit/db-backup.svg)](https://hub.docker.com/r/tiredofit/db-backup)
[![Docker Pulls](https://img.shields.io/docker/pulls/tiredofit/db-backup.svg)](https://hub.docker.com/r/tiredofit/db-backup)
[![Docker Stars](https://img.shields.io/docker/stars/tiredofit/db-backup.svg)](https://hub.docker.com/r/tiredofit/db-backup)
[![Docker Layers](https://images.microbadger.com/badges/image/tiredofit/db-backup.svg)](https://microbadger.com/images/tiredofit/db-backup)

# Introduction

This will build a container for backing up multiple type of DB Servers

Currently backs up CouchDB, InfluxDB, MySQL, MongoDB Postgres, Redis, Rethink servers.

* dump to local filesystem
* select database user and password
* backup all databases
* choose to have an MD5 sum after backup for verification
* delete old backups after specific amount of time
* choose compression type (none, gz, bz, xz)
* connect to any container running on the same system
* select how often to run a dump
* select when to start the first dump, whether time of day or relative to container start time

* This Container uses a [customized Alpine Linux base](https://hub.docker.com/r/tiredofit/alpine) which includes [s6 overlay](https://github.com/just-containers/s6-overlay) enabled for PID 1 Init capabilities, [zabbix-agent](https://zabbix.org) for individual container monitoring, Cron also installed along with other tools (bash,curl, less, logrotate, nano, vim) for easier management. It also supports sending to external SMTP servers.

[Changelog](CHANGELOG.md)

# Authors

- [Dave Conroy](https://github.com/tiredofit)

# Table of Contents

- [Introduction](#introduction)
    - [Changelog](CHANGELOG.md)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
    - [Data Volumes](#data-volumes)
    - [Environment Variables](#environmentvariables)
- [Maintenance](#maintenance)
    - [Shell Access](#shell-access)

# Prerequisites

You must have a working DB server or container available for this to work properly, it does not provide server functionality!


# Installation

Automated builds of the image are available on [Docker Hub](https://hub.docker.com/r/tiredofit/db-backup) and is the recommended
method of installation.


```bash
docker pull tiredofit/db-backup:latest
```

# Quick Start

* The quickest way to get started is using [docker-compose](https://docs.docker.com/compose/). See the examples folder for a working [docker-compose.yml](examples/docker-compose.yml) that can be modified for development or production use.

* Set various [environment variables](#environment-variables) to understand the capabiltiies of this image.
* Map [persistent storage](#data-volumes) for access to configuration and data files for backup.

> **NOTE**: If you are using this with a docker-compose file along with a seperate SQL container, take care not to set the variables to backup immediately, more so have it delay execution for a minute, otherwise you will get a failed first backup.

# Configuration

## Data-Volumes

The following directories are used for configuration and can be mapped for persistent storage.

| Directory | Description |
|-----------|-------------|
| `/backup` | Backups |


## Environment Variables

Along with the Environment Variables from the [Base image](https://hub.docker.com/r/tiredofit/alpine), below is the complete list of available options that can be used to customize your installation.


| Parameter | Description |
|-----------|-------------|
| `COMPRESSION` | Use either Gzip `GZ`, Bzip2 `BZ`, XZip `XZ`, or none `NONE` - Default `GZ`
| `DB_TYPE` | Type of DB Server to backup `couch` `influx` `mysql` `pgsql` `mongo` `redis` `rethink`
| `DB_HOST` | Server Hostname e.g. `mariadb`
| `DB_NAME` | Schema Name e.g. `database`
| `DB_USER` | username for the database - use `root` to backup all MySQL of them.
| `DB_PASS` | (optional if DB doesn't require it) password for the database
| `DB_PORT` | (optional) Set port to connect to DB_HOST. Defaults are provided
| `DB_DUMP_FREQ` | How often to do a dump, in minutes. Defaults to 1440 minutes, or once per day.
| `DB_DUMP_BEGIN` | What time to do the first dump. Defaults to immediate. Must be in one of two formats
| | Absolute HHMM, e.g. `2330` or `0415`
| | Relative +MM, i.e. how many minutes after starting the container, e.g. `+0` (immediate), `+10` (in 10 minutes), or `+90` in an hour and a half
| `DB_CLEANUP_TIME` | Value in minutes to delete old backups (only fired when dump freqency fires). 1440 would delete anything above 1 day old. You don't need to set this variable if you want to hold onto everything.
| `DEBUG_MODE` | If set to `true`, print copious shell script messages to the container log. Otherwise only basic messages are printed.
| `MD5` | Generate MD5 Sum in Directory, `TRUE` or `FALSE` - Default `TRUE`
| `PARALLEL_COMPRESSION` | Use multiple cores when compressing backups `TRUE` or `FALSE` - Default `TRUE` |
| `SPLIT_DB` | If using root as username and multiple DBs on system, set to TRUE to create Seperate DB Backups instead of all in one. - Default `FALSE` |


## Maintenance

Manual Backups can be perforemd by entering the container and typing `backup-now`

#### Shell Access

For debugging and maintenance purposes you may want access the containers shell.

```bash
docker exec -it (whatever your container name is e.g.) db-backup bash
```

