#!/usr/bin/env bash

# load libraries
source /usr/local/bin/lib/message_log.lib
source /usr/local/bin/lib/check_vars.lib
source /usr/local/bin/lib/check_error.lib

log_message "######################################"
log_message "###### Start Configuring Server ######"

#PATH_BIN_SHELL_TOOLS="/bin/"
date_now="$(date +"Y%Ym%md%d-H%HM%MS%S")"



function config_nginx() {
	log_message "## SETTING NGINX"

	#check_vars DATABASE_NAME_WORDPRESS DATABASE_HOST DATABASE_WORDPRESS_USER DATABASE_WORDPRESS_PASS

    cp -r /srv/config/nginx/*  /etc/nginx/

    local config_file="/etc/nginx/sites-available/sample-proxy-hostname.domain.tld.conf"

    # enabling site

    cd /etc/nginx/sites-enabled/
    ln -s ${config_file}

}


function config_ssl_sef_signed(){
	log_message "## SETTING SSL self-signed"

    mkdir -p /etc/ssl/private/
    mkdir -p /etc/ssl/certs/

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=country/ST=State/L=Province/O=xpto/OU=SRE/CN=xpto.com"

    openssl dhparam -out /etc/nginx/dhparam.pem 4096

    echo '
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    ' > /etc/nginx/snippets/self-signed.conf

    echo '
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/nginx/dhparam.pem; 
    ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
    ssl_ecdh_curve secp384r1;
    ssl_session_timeout  10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    # Disable strict transport security for now. You can uncomment the following
    # line if you understand the implications.
    #add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    ' > /etc/nginx/snippets/ssl-params.conf

}

function config_crontab() {
    log_message "## SETTING CRONTAB"
    ## setting crontab
    (crontab -l ; echo "0 1 * * * bash /usr/local/bin/backup.sh -d '/var/backups/' -r 7 '/etc/nginx/'")| crontab - 
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

    config_nginx
    check_error $?

    config_ssl_sef_signed
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
