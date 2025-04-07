#!/usr/bin/env bash

# load libraries
source /usr/local/bin/lib/message_log.lib
source /usr/local/bin/lib/check_vars.lib
source /usr/local/bin/lib/check_error.lib

log_message "######################################"
log_message "###### Start Configuring Server ######"

#PATH_BIN_SHELL_TOOLS="/bin/"
date_now="$(date +"Y%Ym%md%d-H%HM%MS%S")"



function config_certbot() {
	log_message "## SETTING CERTBOT"
	log_message " - Creating Certificate"

    if [[ "${STARTUP_PROVISION_CERTIFICATE}" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
        log_message " - Starting Certificate Provision"

        check_vars CERTBOT_CERTIFICATE_TYPE CERTBOT_CERTIFICATE_PLUGIN CERTBOT_CERTIFICATE_SITE_DOMAIN CERTBOT_CERTIFICATE_EMAIL

        local command_options

        if [[ "${CERTBOT_CERTIFICATE_TYPE}" != "" ]]; then
            command_options="${command_options} -t ${CERTBOT_CERTIFICATE_TYPE} "
        fi
        if [[ "${CERTBOT_CERTIFICATE_PLUGIN}" != "" ]]; then
            command_options="${command_options} -p ${CERTBOT_CERTIFICATE_PLUGIN} "
        fi
        if [[ "${CERTBOT_CERTIFICATE_SITE_NAME}" != "" ]]; then
            command_options="${command_options} -s ${CERTBOT_CERTIFICATE_SITE_NAME} "
        fi
        if [[ "${CERTBOT_CERTIFICATE_SITE_DOMAIN}" != "" ]]; then
            command_options="${command_options} -d ${CERTBOT_CERTIFICATE_SITE_DOMAIN} "
        fi
        if [[ "${CERTBOT_CERTIFICATE_EMAIL}" != "" ]]; then
            command_options="${command_options} -e ${CERTBOT_CERTIFICATE_EMAIL} "
        fi
        if [[ "${CERTBOT_CERTIFICATE_WEBROOT}" != "" ]]; then
            command_options="${command_options} -w ${CERTBOT_CERTIFICATE_WEBROOT} "
        fi
        if [[ "${CERTBOT_CERTIFICATE_API_TOKEN}" != "" ]]; then
            command_options="${command_options} -a \"${CERTBOT_CERTIFICATE_API_TOKEN}\" "
        fi

        bash make_cert.sh ${command_options}
        check_error $?

        log_message " - Setting renew on Crontab"
        local log_file="/var/log/letsencrypt/renew.log"
        mkdir -p $(dirname ${log_file})
        touch ${log_file}
        chmod ug+rw ${log_file}
        (crontab -l ; echo "1 0 * * * certbot renew --dry-run --quiet && certbot renew >> ${log_file}")| crontab - 
    else
        log_message " - Skip Certificate Provision"
    fi

}

function config_backup_with_git() {
    log_message "## SETTING Backup On GIT"

    local git_path="/etc/letsencrypt/"

    cd $git_path
    git init .
    git config --global --add safe.directory ${git_path}
    git add .
    git commit -m "backup with git = first commit"

    (crontab -l ; echo "0 0 * * * cd ${git_path} && git add . && git commit -m \"backup with git = host: \$(hostname) - date: \$(date)\"")| crontab - 
}

function config_backup() {
    log_message "## SETTING Backup"
    ## setting crontab
    (crontab -l ; echo "0 1 * * 0 bash /usr/local/bin/backup.sh -d '/var/backups/' -r 4 '/etc/letsencrypt/'")| crontab - 
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

    config_certbot
    check_error $?

    config_backup_with_git
    check_error $?

    config_backup
    check_error $?

    config_supervisor
    check_error $?

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
