#!/bin/bash
cd "$(dirname "$(realpath "$0")")"

cd ..
# creating hardlinks
paths="certbot  mariadb  nextcloud  nginx  portainer wordpress"
for p in ${paths}; do
    cd ${p}/config/bin/
    echo "PATH: $(pwd)"

    ln ../../../scripts/backup.sh
    ln ../../../scripts/healthcheck.sh
    ln ../../../scripts/config_dns.sh

    mkdir -p lib 
    cd lib
    ln ../../../../scripts/lib/check_error.lib
    ln ../../../../scripts/lib/check_vars.lib
    ln ../../../../scripts/lib/message_log.lib
    cd ..

    cd ../../../
done

