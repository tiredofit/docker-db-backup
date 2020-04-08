## 1.18.2 2020-04-08 <hyun007 @ github>

   ### Changed
      - Rework to allow passwords with spaces in them for MariaDB / MySQL

## 1.18.1 2020-03-14 <dave at tiredofit dot ca>

   ### Changed
      - Allow for passwords with spaces in them for MariaDB / MySQL


## 1.18.0 2019-12-29 <dave at tiredofit dot ca>

   ### Added
      - Update image to support new tiredofit/alpine base images


## 1.17.3 2019-12-12 <dave at tiredofit dot ca>

   ### Changed
      - Quiet down Zabbix Agent


## 1.17.2 2019-12-12 <dave at tiredofit dot ca>

   ### Changed
      - Re Enable ZABBIX


## 1.17.1 2019-12-10 <dave at tiredofit dot ca>

   ### Changed
      - Fix spelling mistake in container initialization


## 1.17.0 2019-12-09 <dave at tiredofit dot ca>

   ### Changed
      - Stop compiling mongodb-tools as it is back in Alpine:edge repositories
      - Cleanup Code


## 1.16 - 2019-06-16 - <dave at tiredofit dot ca>

* Check to see if Database Exists before performing backup
* Fix for MysQL/MariaDB custom ports - Credit to <spumer@github>

## 1.15 - 2019-05-24 - <claudioaltamura @ github>

* Added abaility to backup password protected Redis Hosts

## 1.14 - 2019-04-20 - <dave at tiredofit dot ca>

* Switch to using locally built mongodb-tools from tiredofit/mongo-builder due to Alpine removing precompiled packages from repositories

## 1.13 - 2019-03-09 - <dave at tiredofit dot ca>

* Fixed Postgres backup without SPLIT_DB enabled (credit MelwinKfr@github)
* Added DB_PORT reference to properly backup Postgres with non default ports (thanks Maxximus007@github)

## 1.12 - 2019-03-01 - <stevetodorov at github>

* Fix for XZ Compression failing

## 1.11 - 2018-11-19 - <skylord123 at github>

* Fix for Urnary Operator Error

## 1.10 - 2018-11-19 - <dave at tiredofit dot ca>

* Fix for InfluxDB for backing up and supporting DB_PORT variable - Thanks skylord123@github

## 1.9 - 2018-11-03 - <dave at tiredofit dot ca>

* Switch from OpenSSL to LibreSSL

## 1.8 - 2018-07-18 - <dave at tiredofit dot ca>

* Fix warnings on startup related to 1.7 Changes

## 1.7 - 2018-06-06 - <dave at tiredofit dot ca>

* Added ability for Manual Backup (enter container and type `backup-now`)

## 1.6 - 2018-02-26 - <dave at tiredofit dot ca>

* Add Parallel Compression mode (Default TRUE

## 1.5 - 2018-01-28 - <dave at tiredofit dot ca>

* Add Zabbix Checks

## 1.4 - 2017-11-17 - <dave at tiredofit dot ca>

* Switch to Packages Postgres

## 1.31 - 2017-11-17 - <dave at tiredofit dot ca>

* Fix to SPLIT_DB Postgresql Backup

## 1.3 - 2017-10-25 - <dave at tiredofit dot ca>

* Remove Alpine postgres package and recompile version 10

## 1.2 - 2017-10-19 - <dave at tiredofit dot ca>

* Syntax Error Fix
* Fix some environment variables for Postgres and Redis

## 1.1 - 2017-09-14 - <dave at tiredofit dot ca>

* Added CouchDB

## 1.0 - 2017-09-14 - <dave at tiredofit dot ca>

* Initial Release
* Alpine:Edge

