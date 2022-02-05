# github.com/tiredofit/docker-db-backup

[![GitHub release](https://img.shields.io/github/v/tag/tiredofit/docker-db-backup?style=flat-square)](https://github.com/tiredofit/docker-db-backup/releases/latest)
[![Build Status](https://img.shields.io/github/workflow/status/tiredofit/docker-db-backup/build?style=flat-square)](https://github.com/tiredofit/docker-db-backup/actions?query=workflow%3Abuild)
[![Docker Stars](https://img.shields.io/docker/stars/tiredofit/db-backup.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/tiredofit/db-backup/)
[![Docker Pulls](https://img.shields.io/docker/pulls/tiredofit/db-backup.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/tiredofit/db-backup/)
[![Become a sponsor](https://img.shields.io/badge/sponsor-tiredofit-181717.svg?logo=github&style=flat-square)](https://github.com/sponsors/tiredofit)
[![Paypal Donate](https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal&style=flat-square)](https://www.paypal.me/tiredofit)

* * *
## About

This will build a container for backing up multiple types of DB Servers

Currently backs up CouchDB, InfluxDB, MySQL, MongoDB, Postgres, Redis servers.

* dump to local filesystem or backup to S3 Compatible services
* select database user and password
* backup all databases
* choose to have an MD5 sum after backup for verification
* delete old backups after specific amount of time
* choose compression type (none, gz, bz, xz, zstd)
* connect to any container running on the same system
* select how often to run a dump
* select when to start the first dump, whether time of day or relative to container start time
* Execute script after backup for monitoring/alerting purposes

## Maintainer

- [Dave Conroy](https://github.com/tiredofit)

## Table of Contents

- [About](#about)
- [Maintainer](#maintainer)
- [Table of Contents](#table-of-contents)
- [Prerequisites and Assumptions](#prerequisites-and-assumptions)
- [Installation](#installation)
  - [Build from Source](#build-from-source)
  - [Prebuilt Images](#prebuilt-images)
- [Configuration](#configuration)
  - [Quick Start](#quick-start)
  - [Persistent Storage](#persistent-storage)
  - [Environment Variables](#environment-variables)
    - [Base Images used](#base-images-used)
    - [Backing Up to S3 Compatible Services](#backing-up-to-s3-compatible-services)
- [Maintenance](#maintenance)
  - [Shell Access](#shell-access)
  - [Manual Backups](#manual-backups)
  - [Custom Scripts](#custom-scripts)
- [Support](#support)
  - [Usage](#usage)
  - [Bugfixes](#bugfixes)
  - [Feature Requests](#feature-requests)
  - [Updates](#updates)
- [License](#license)

## Prerequisites and Assumptions

You must have a working DB server or container available for this to work properly, it does not provide server functionality!

## Installation

### Build from Source
Clone this repository and build the image with `docker build -t (imagename) .`

### Prebuilt Images
Builds of the image are available on [Docker Hub](https://hub.docker.com/r/tiredofit/db-backup) and is the recommended method of installation.

```bash
docker pull tiredofit/db-backup:(imagetag)
```

The following image tags are available along with their tagged release based on what's written in the [Changelog](CHANGELOG.md):

| Container OS | Tag       |
| ------------ | --------- |
| Alpine       | `:latest` |


## Configuration

### Quick Start

* The quickest way to get started is using [docker-compose](https://docs.docker.com/compose/). See the examples folder for a working [docker-compose.yml](examples/docker-compose.yml) that can be modified for development or production use.

* Set various [environment variables](#environment-variables) to understand the capabiltiies of this image.
* Map [persistent storage](#data-volumes) for access to configuration and data files for backup.

> **NOTE**: If you are using this with a docker-compose file along with a seperate SQL container, take care not to set the variables to backup immediately, more so have it delay execution for a minute, otherwise you will get a failed first backup.
### Persistent Storage

The following directories are used for configuration and can be mapped for persistent storage.

| Directory                | Description                                                                        |
| ------------------------ | ---------------------------------------------------------------------------------- |
| `/backup`                | Backups                                                                            |
| `/assets/custom-scripts` | *Optional* Put custom scripts in this directory to execute after backup operations |
### Environment Variables

#### Base Images used

This image relies on an [Alpine Linux](https://hub.docker.com/r/tiredofit/alpine) base image that relies on an [init system](https://github.com/just-containers/s6-overlay) for added capabilities. Outgoing SMTP capabilities are handlded via `msmtp`. Individual container performance monitoring is performed by [zabbix-agent](https://zabbix.org). Additional tools include: `bash`,`curl`,`less`,`logrotate`, `nano`,`vim`.

Be sure to view the following repositories to understand all the customizable options:

| Image                                                  | Description                            |
| ------------------------------------------------------ | -------------------------------------- |
| [OS Base](https://github.com/tiredofit/docker-alpine/) | Customized Image based on Alpine Linux |


| Parameter                  | Description                                                                                                                                                                                        | Default         |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `BACKUP_LOCATION`          | Backup to `FILESYSTEM` or `S3` compatible services like S3, Minio, Wasabi                                                                                                                          | `FILESYSTEM`    |
| `COMPRESSION`              | Use either Gzip `GZ`, Bzip2 `BZ`, XZip `XZ`, ZSTD `ZSTD` or none `NONE`                                                                                                                            | `GZ`            |
| `COMPRESSION_LEVEL`        | Numberical value of what level of compression to use, most allow `1` to `9` except for `ZSTD` which allows for `1` to `19` -                                                                       | `3`             |
| `DB_AUTH`                  | (Mongo Only - Optional) Authentication Database                                                                                                                                                    |                 |
| `DB_TYPE`                  | Type of DB Server to backup `couch` `influx` `mysql` `pgsql` `mongo` `redis` `sqlite3`                                                                                                             |                 |
| `DB_HOST`                  | Server Hostname e.g. `mariadb`. For `sqlite3`, full path to DB file e.g. `/backup/db.sqlite3`                                                                                                      |                 |
| `DB_NAME`                  | Schema Name e.g. `database`                                                                                                                                                                        |                 |
| `DB_USER`                  | username for the database - use `root` to backup all MySQL of them.                                                                                                                                |                 |
| `DB_PASS`                  | (optional if DB doesn't require it) password for the database                                                                                                                                      |                 |
| `DB_PORT`                  | (optional) Set port to connect to DB_HOST. Defaults are provided                                                                                                                                   | varies          |
| `DB_DUMP_FREQ`             | How often to do a dump, in minutes. Defaults to 1440 minutes, or once per day.                                                                                                                     | `1440`          |
| `DB_DUMP_BEGIN`            | What time to do the first dump. Defaults to immediate. Must be in one of two formats                                                                                                               |                 |
|                            | Absolute HHMM, e.g. `2330` or `0415`                                                                                                                                                               |                 |
|                            | Relative +MM, i.e. how many minutes after starting the container, e.g. `+0` (immediate), `+10` (in 10 minutes), or `+90` in an hour and a half                                                     |                 |
| `DB_CLEANUP_TIME`          | Value in minutes to delete old backups (only fired when dump freqency fires). 1440 would delete anything above 1 day old. You don't need to set this variable if you want to hold onto everything. | `FALSE`         |
| `DEBUG_MODE`               | If set to `true`, print copious shell script messages to the container log. Otherwise only basic messages are printed.                                                                             |                 |
| `EXTRA_OPTS`               | If you need to pass extra arguments to the backup command, add them here e.g. `--extra-command`                                                                                                    |                 |
| `MYSQL_MAX_ALLOWED_PACKET` | Max allowed packet if backing up MySQL / MariaDB                                                                                                                                                   | `512M`          |
| `MD5`                      | Generate MD5 Sum in Directory, `TRUE` or `FALSE`                                                                                                                                                   | `TRUE`          |
| `PARALLEL_COMPRESSION`     | Use multiple cores when compressing backups `TRUE` or `FALSE`                                                                                                                                      | `TRUE`          |
| `POST_SCRIPT`              | Fill this variable in with a command to execute post the script backing up                                                                                                                         |                 |
| `SPLIT_DB`                 | If using root as username and multiple DBs on system, set to TRUE to create Seperate DB Backups instead of all in one.                                                                             | `FALSE`         |
| `TEMP_LOCATION`            | Perform Backups and Compression in this temporary directory                                                                                                                                        | `/tmp/backups/` |

- When using compression with MongoDB, only `GZ` compression is possible.
- You may need to wrap your `DB_DUMP_BEGIN` value in quotes for it to properly parse. There have been reports of backups that start with a `0` get converted into a different format which will not allow the timer to start at the correct time.



#### Backing Up to S3 Compatible Services

If `BACKUP_LOCATION` = `S3` then the following options are used.

| Parameter       | Description                                                                             |
| --------------- | --------------------------------------------------------------------------------------- |
| `S3_BUCKET`     | S3 Bucket name e.g. `mybucket`                                                          |
| `S3_ENDPOINT`   | URL of S3-compatible endpoint, e.g. `http://minio:8080`                                 |
| `S3_KEY_ID`     | S3 Key ID                                                                               |
| `S3_KEY_SECRET` | S3 Key Secret                                                                           |
| `S3_PATH`       | S3 Pathname to save to e.g. '`backup`'                                                  |
| `S3_PROTOCOL`   | Use either `http` or `https` to access service - Default `https`                        |
| `S3_REGION`     | Define region in which bucket is defined. Example: `ap-northeast-2`                     |


## Maintenance


### Shell Access

For debugging and maintenance purposes you may want access the containers shell.

``bash
docker exec -it (whatever your container name is) bash
``
### Manual Backups
Manual Backups can be performed by entering the container and typing `backup-now`


### Custom Scripts

If you want to execute a custom script at the end of backup, you can drop bash scripts with the extension of `.sh` in this directory. See the following example to utilize:

````bash
$ cat post-script.sh
##!/bin/bash

# #### Example Post Script
# #### $1=EXIT_CODE (After running backup routine)
# #### $2=DB_TYPE (Type of Backup)
# #### $3=DB_HOST (Backup Host)
# #### #4=DB_NAME (Name of Database backed up
# #### $5=DATE (Date of Backup)
# ####  $6=TIME (Time of Backup)
# ####  $7=BACKUP_FILENAME (Filename of Backup)
# ####  $8=FILESIZE (Filesize of backup)
# ####  $9=MD5_RESULT (MD5Sum if enabled)

echo "${1} ${2} Backup Completed on ${3} for ${4} on ${5} ${6}. Filename: ${7} Size: ${8} bytes MD5: ${9}"
````

Outputs the following on the console:

`0 mysql Backup Completed on example-db for example on 2020-04-22 05:19:10. Filename: mysql_example_example-db_20200422-051910.sql.bz2 Size: 7795 bytes MD5: 952fbaafa30437494fdf3989a662cd40`

If you wish to change the size value from bytes to megabytes set environment variable `SIZE_VALUE=megabytes`

## Support

These images were built to serve a specific need in a production environment and gradually have had more functionality added based on requests from the community.
### Usage
- The [Discussions board](../../discussions) is a great place for working with the community on tips and tricks of using this image.
- Consider [sponsoring me](https://github.com/sponsors/tiredofit) personalized support.
### Bugfixes
- Please, submit a [Bug Report](issues/new) if something isn't working as expected. I'll do my best to issue a fix in short order.

### Feature Requests
- Feel free to submit a feature request, however there is no guarantee that it will be added, or at what timeline.
- Consider [sponsoring me](https://github.com/sponsors/tiredofit) regarding development of features.

### Updates
- Best effort to track upstream changes, More priority if I am actively using the image in a production environment.
- Consider [sponsoring me](https://github.com/sponsors/tiredofit) for up to date releases.

## License
MIT. See [LICENSE](LICENSE) for more details.
