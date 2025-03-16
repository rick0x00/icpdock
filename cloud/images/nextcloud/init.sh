#!/bin/bash
args="$*"

log_message() {
    REGISTER_LOG="/var/log/config.log"
    local message="$*"
    local content_log=""
    content_log="[$(date '+%Y-%m-%d %H:%M:%S')] - $message"
    echo "${content_log}" >> "${REGISTER_LOG}"
    echo "${content_log}" 
}

log_message "##########################################"
log_message "##           INICIANDO DOCKER           ##"
log_message "##########################################"

function config_crontab() {
        log_message "# configurando crontab"
        ## configuracao do crontab
        (echo "0 1 * * * bash /usr/local/bin/create_backup.sh '/var/lib/mysql/' '/etc/mysql/' >> /var/backups/register.log 2>&1")| crontab -
        (crontab -l ; echo "") | crontab -
        mkdir -p /var/backups/

}

config_crontab


log_message "###### CONFIGURANDO resolv.conf ######"
/usr/local/bin/config_resolv_conf.sh
# verificando  se a configuracao funcionou corretamente
if [ $? -eq 0 ]; then
	log_message "configuracao OK"
else
	log_message "ERROR: problema de configuracao"
	exit 1
fi


#/usr/sbin/cron -f
/usr/local/bin/docker-entrypoint.sh ${args}