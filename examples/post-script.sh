##!/bin/bash

## Example Post Script
## $1=DB_TYPE (Type of Backup)
## $2=DB_HOST (Backup Host)
## #3=DB_NAME (Name of Database backed up
## $4=DATE (Date of Backup)
## $5=TIME (Time of Backup)
## $6=BACKUP_FILENAME (Filename of Backup)
## $7=FILESIZE (Filesize of backup)
## $8=MD5_RESULT (MD5Sum if enabled)

echo "${1} Backup Completed on ${2} for ${3} on ${4} ${5}. Filename: ${6} Size: ${7} bytes MD5: ${8}"
