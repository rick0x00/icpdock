#!/usr/bin/env bash

# load libraries
source /usr/local/bin/lib/message_log.lib
source /usr/local/bin/lib/check_vars.lib
source /usr/local/bin/lib/check_error.lib

log_message "######################################"
log_message "###### Start Configuring Server ######"

#PATH_BIN_SHELL_TOOLS="/bin/"
date_now="$(date +"Y%Ym%md%d-H%HM%MS%S")"


function config_apache() {
	log_message "## SETTING APACHE"

	check_vars SITE_HTTP_PORT SITE_HTTPS_PORT SITE_PATH_APP SITE_SSL_ENABLED SITE_NAME SITE_DOMAIN

    cp -r /srv/config/apache/*  /etc/apache2/


    local site_http_port="${SITE_HTTP_PORT:-80}"
    local site_https_port="${SITE_HTTPS_PORT:-443}"

    local site_path="${SITE_PATH_APP:-'/var/www/html'}"
    local site_ssl_enabled="${SITE_SSL_ENABLED:-false}"
    local site_name="${SITE_NAME:-wordpress}"
    local site_subdomain="${site_name:-debian}"
    local site_root_domain="${SITE_DOMAIN:-local}"

    local site_config_file_name="${site_name}.conf"
    local site_config_file_uri="/etc/apache2/sites-available/${site_config_file_name}"

    # setting apache server to listening on specified ports
    sed -i "/Listen 80/s/80/${site_http_port}/" /etc/apache2/ports.conf
    sed -i "/Listen 443/s/443/${site_https_port}/" /etc/apache2/ports.conf

    # copy sample file
    cp "/etc/apache2/sites-available/site_sample.conf" "${site_config_file_uri}"

    # setting site
    sed -i "s/SITE_HTTP_PORT/${site_http_port}/" "${site_config_file_uri}"
    sed -i "s/SITE_HTTPS_PORT/${site_https_port}/" "${site_config_file_uri}"
    sed -i "s|SITE_PATH|${site_path}|" "${site_config_file_uri}"
    sed -i "s/SITE_NAME/${site_subdomain}/" "${site_config_file_uri}"
    sed -i "s/SITE_DOMAIN/${site_root_domain}/" "${site_config_file_uri}"

    # check if site use SSL enabled
    if [ "${site_ssl_enabled}" == "true" ] || [ "${site_ssl_enabled}" == "yes" ]; then
        # SSL Enabled on site
        # Enable SSL page
        # enabling http page redirect for https page
        sed -i "/#Redirect/s/#Redirect/Redirect/" "${site_config_file_uri}"
        # Configuring SSL options on page
        sed -i "/SSL/s/#//" "${site_config_file_uri}"
        sed -i "/Include/s/#//" "${site_config_file_uri}"
    else
        # SSL Disabled on site
        # enabling http page work
        sed -i "/DocumentRoot/s/#//" "${site_config_file_uri}"
    fi

    # enabling site
    # a2ensite ${site_config_file_name}
    # ln -s "${site_config_file_name}" /etc/apache2/sites-enabled/

}


function config_crontab() {
    log_message "## SETTING CRONTAB"
    ## setting crontab
    (crontab -l ; echo "0 1 * * * bash /usr/local/bin/backup.sh -d '/var/backups/' -r 7 '/etc/apache2/'")| crontab - 
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

    config_apache
    check_error $?

    config_crontab
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
