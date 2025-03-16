#!/usr/bin/env bash

# load libraries
source /usr/local/bin/lib/message_log.lib
source /usr/local/bin/lib/check_vars.lib
source /usr/local/bin/lib/check_error.lib

log_message "######################################"
log_message "###### Start Configuring Server ######"

#PATH_BIN_SHELL_TOOLS="/bin/"
date_now="$(date +"Y%Ym%md%d-H%HM%MS%S")"

function config_mariadb() {
	log_message "## SETTING MARIADB"

	#check_vars DATABASE_NAME_WORDPRESS DATABASE_HOST DATABASE_WORDPRESS_USER DATABASE_WORDPRESS_PASS

    ARG TZ=UTC

    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone

    cp /srv/config/mariadb/my.cnf  /etc/mysql/conf.d/my.cnf

    chown -R mysql:mysql /var/lib/mysql/ 
    chmod 0444 /etc/mysql/conf.d/my.cnf

}


function config_crontab() {
    log_message "## SETTING CRONTAB"
    ## setting crontab
    (crontab -l ; echo "0 1 * * * bash /usr/local/bin/backup.sh -d '/var/backups/' -r 7 '/var/lib/mysql/' '/etc/mysql/'")| crontab - 
    (crontab -l ; echo "") | crontab -
    mkdir -p /var/backups/

}

function config_supervisor(){
    log_message "## SETTING SUPERVISOR"
    # setting supervisor

    # copy all necessary files to supervisor directory
    cp /srv/config/supervisor/*.conf /etc/supervisor/conf.d/

}


function config_server() {
    # call all functions to configure server

    config_mariadb
    check_error $?

    config_crontab
    check_error $?

    #config_supervisor
    #check_error $?

}

app_name="${CLIENT_NAME}.${SYSTEM_NAME}"
srv_trigger="/srv/config/${app_name}.trigger"

# check if ${app_name} are created
if [ -f "${srv_trigger}" ] ; then
    # server already configured
    log_message "# Server already configured."

    #if you want reconfigure, set var "FORCE_RECONFIG=true"...
    if [ "true" == "${FORCE_RECONFIG}" ] ; then
        # forcing reconfiguration

        log_message "# forcing... "
        log_message "# configuring server... "
        config_server
    else
        # skip reconfiguration
        log_message "# skipping..."
    fi

else
    log_message "# configuring server..."
    config_server

    # create trigger file
    echo "# trigger file of ${app_name}, server already configured " > "${srv_trigger}"
fi

log_message "END of configuration script"

log_message "######################################"
