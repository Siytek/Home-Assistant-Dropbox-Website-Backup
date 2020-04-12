# Home Assistant Website Backup Manager script V0.1
# Pushes a backup copy of the website and SQL database to Dropbox
# Triggered and controled by Home Assistant Frontend
# For more information visit https://siytek.com
# The awesome Home Assistant: https://home-assistant.io

#!/bin/bash

# Script config
thedate="-"$(date +"%d_%m_%Y")
datetime=$(date '+%d/%m/%Y %H:%M:%S');
website_path=$6 # Path to website root folder
overwrite=$1
log_path=$8

# SQL credentials
username="$2"
database="$3"
password="$4"

# Dropbox config
dropbox_key="$5"
dropbox_path=$7 # Backup storage location

# Back up the database locally
echo -n "Backing up database..."

# Create defaults file
echo "[mysqld]" > sql_pw
echo "[mysqldump]" >> sql_pw
echo "password=""'"${password}"'" >> sql_pw

# If database overwrite set to FALSE then add dated backup
if [ $overwrite = "off" ]; then
        echo " adding new backup database-backup${thedate}.sql"
        mysqldump --defaults-file=./sql_pw --single-transaction -u ${username} ${database} > ./database-backup${thedate}.sql
# Else just overwrite the same database backup each time

else
    	echo " overwriting database-backup.sql"
        mysqldump --defaults-file=./sql_pw --single-transaction -u ${username} ${database} > ./database-backup.sql
        thedate=""
fi

# Removing defaults file
rm sql_pw

# Backup database to Dropbox
echo "Transfering database to Dropbox..."
curl -X POST "https://content.dropboxapi.com/2/files/upload" \
    --header "Authorization: Bearer ${dropbox_key}" \
    --header "Dropbox-API-Arg: {\"path\": \"${dropbox_path}/database-backup${thedate}.sql\",\"mode\": \"overwrite\",\"autorename\": true,\"mute\": false}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @database-backup${thedate}.sql \
    > ./dropbox_database_backup.log


echo "Backing up archive to Dropbox..."

rm dropbox_website_backup.log
for file in $(find ${website_path} -name '*' -type f); do

       curl -X POST "https://content.dropboxapi.com/2/files/upload" \
       --header "Authorization: Bearer ${dropbox_key}" \
       --header "Dropbox-API-Arg: {\"path\": \"${dropbox_path}${file#${website_path}}\",\"mode\": \"overwrite\",\"autorename\": true,\"mute\": false}" \
       --header "Content-Type: application/octet-stream" \
       --data-binary @$file \
       >> ./dropbox_website_backup.log
done

# Writing to the log file
echo "Writing date and time to ${website_path}/dropbox_backup.log"
echo ${datetime} > $log_path

echo "Done!"
