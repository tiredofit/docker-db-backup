##!/bin/bash

## Example Post Script
## $1=EXIT_CODE (After running backup routine)
## $2=DB_TYPE (Type of Backup)
## $3=DB_HOST (Backup Host)
## #4=DB_NAME (Name of Database backed up
## $5=DATE (Date of Backup)
## $6=TIME (Time of Backup)
## $7=BACKUP_FILENAME (Filename of Backup)
## $8=FILESIZE (Filesize of backup)
## $9=MD5_RESULT (MD5Sum if enabled)

echo "${1} ${2} Backup Completed on ${3} for ${4} on ${5} ${6}. Filename: ${7} Size: ${8} bytes MD5: ${9}"
