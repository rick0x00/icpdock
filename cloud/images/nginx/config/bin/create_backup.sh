#!/usr/bin/env bash

LIST_TO_BACKUP="$*"

STORAGE_BACKUPS="/var/backups"
date_now="$(date +'%Y%m%d')"

echo "Creating backups"
echo "storage de backups: ${STORAGE_BACKUPS}"


function create_file_bkp() {
	cd /
    local backup_filename="${STORAGE_BACKUPS}/bkp_host-$(hostname)-files-$(echo $path_to_backup | tr '/' '_')-date_${date_now}.tar.gz"
    echo "criando arquivo: $backup_filename"
	tar -czf "${backup_filename}" "${path_to_backup}"
	cd -
}


for path_to_backup in $LIST_TO_BACKUP; do 
    echo "creating backup: $path_to_backup ..."
    create_file_bkp
done

echo "End of backup"
