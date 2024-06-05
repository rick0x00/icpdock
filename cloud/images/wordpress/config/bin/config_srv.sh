#!/usr/bin/env bash

# load libraries
source /usr/local/bin/lib/message_log.lib
source /usr/local/bin/lib/check_vars.lib
source /usr/local/bin/lib/check_error.lib

log_message "######################################"
log_message "###### Start Configuring Server ######"

#PATH_BIN_SHELL_TOOLS="/bin/"
date_now="$(date +"Y%Ym%md%d-H%HM%MS%S")"


function config_database() {
	log_message "## SETTING DATABASE"

	check_vars DATABASE_HOST DATABASE_PORT DATABASE_CONFIG_MODE DATABASE_APP_USER DATABASE_APP_PASS DATABASE_SCHEMA_NAME DATABASE_SCHEMA_CHARSET DATABASE_SCHEMA_COLLATE

    local database_host=${DATABASE_HOST:-localhost}
    local database_port=${DATABASE_PORT:-3306}
    local database_config_mode=${DATABASE_CONFIG_MODE:-master}
    local database_admin_user=${DATABASE_ADMIN_USER:-root}
    local database_admin_pass=${DATABASE_ADMIN_PASS:-""}
    local database_app_user=${DATABASE_APP_USER:-wordpress_user}
    local database_app_pass=${DATABASE_APP_PASS:-wordpress_pass}
    local database_schema_name=${DATABASE_SCHEMA_NAME:-wordpress_db}
    local database_schema_charset=${DATABASE_SCHEMA_CHARSET:-utf8mb4}
    local database_schema_collate=${DATABASE_SCHEMA_COLLATE:-utf8mb4_unicode_ci}

	function check_database_is_alive() {
		# Checking if DATABASE Server is alive
		log_message "## Checking if DATABASE Server is alive"
		# Retry settings
		local max_retries=30
		local delay_between_retries=10

		for ((i=1; i<=$max_retries; i++)); do
		    # Try to connect to DATABASE
		    mysql -h"${database_host}" -u"${$database_admin_user}" -p"${database_admin_pass}" -e "SELECT VERSION();" || \
		    mysqladmin -h ${database_host} ping || \
            nc -zv ${database_host} ${database_port}

		    # Check the exit code of the previous command
		    if [ $? -eq 0 ]; then
		        log_message "# DATABASE is ALIVE"
		        break
		    else
		        log_message "# DATABASE is NOT ALIVE"
		        log_message "# Attempt $i of $max_retries: Unable to connect to DATABASE server."
		        if [ $i -lt $max_retries ]; then
		            log_message "# Waiting $delay_between_retries seconds before the next attempt..."
		            sleep $delay_between_retries
		        else
		            log_message "# Exceeded the maximum number of retries. Aborting the script."
		            exit 1
		        fi
		    fi
		done
	}


	function config_database_schema_user() {
		# setting database schema and user

		log_message "# Creating database schema: $database_schema_name;"
		mysql -h"${database_host}" -u"${$database_admin_user}" -p"${database_admin_pass}" --execute "DROP DATABASE IF EXISTS ${database_schema_name};" 
		mysql -h"${database_host}" -u"${$database_admin_user}" -p"${database_admin_pass}" --execute "CREATE DATABASE ${database_schema_name};" 
 
		log_message "# Creating user: ${database_app_user};"
		mysql -h"${database_host}" -u"${$database_admin_user}" -p"${database_admin_pass}" --execute "DROP USER IF EXISTS '${database_app_user}';" 
		mysql -h"${database_host}" -u"${$database_admin_user}" -p"${database_admin_pass}" --execute "CREATE USER '${database_app_user}'@'%' IDENTIFIED BY '${database_app_pass}';"

		log_message "# Adjusting user privileges to database"
		mysql -h"${database_host}" -u"${$database_admin_user}" -p"${database_admin_pass}" --execute "GRANT ALL PRIVILEGES ON ${database_schema_name}.* TO '${database_app_user}'@'%';" 
		mysql -h"${database_host}" -u"${$database_admin_user}" -p"${database_admin_pass}" --execute "FLUSH PRIVILEGES;"

	}


    function check_database_schema_exists() {
        # check database exists(
        mysql -h"${database_host}" -u"${$database_admin_user}" -p"${database_admin_pass}" -e "show databases;" | grep $database_schema_name 
        if [[ $? -eq 0 ]]; then
            log_message "# DATABASE SCHEMA \'$database_schema_name\'already exists..."
            log_message "# use 'FORCE_RECONFIG=true' to force reconfigurations."
            if [ "true" == "${FORCE_RECONFIG}" ] ; then
                log_message "# FORCING reconfiguration..."
                # force reconfiguration
                config_database_schema_user
            else
                log_message "# skipping reconfigurations..."
            fi
        else
            log_message "# DATABASE SCHEMA \'$database_schema_name\' not detected..."
            config_database_schema_user
            check_error $?
        fi
    }


    function check_database_configuration_mode() {
        if [[ "$DATABASE_CONFIG_MODE" == "SLAVE" ]] | [[ "$DATABASE_CONFIG_MODE" == "slave" ]] ; then
            log_message "# DATABASE configuration mode: SLAVE"
            
            # if slave, the vars is necessary
            check_vars DATABASE_ADMIN_USER DATABASE_ADMIN_PASS

            check_database_is_alive
            check_error $?
            check_database_schema_exists
            check_error $?
        else
            log_message "# DATABASE configuration mode: MASTER"
            log_message "# skipping database configuration..."
        fi
    }


    check_database_configuration_mode

}

function config_wordpress() {
	log_message "## SETTING WORDPRESS"

    check_vars DATABASE_HOST DATABASE_PORT DATABASE_APP_USER DATABASE_APP_PASS DATABASE_SCHEMA_NAME DATABASE_SCHEMA_CHARSET DATABASE_SCHEMA_COLLATE

    local database_host=${DATABASE_HOST:-localhost}
    local database_port=${DATABASE_PORT:-3306}
    local database_app_user=${DATABASE_APP_USER:-wordpress_user}
    local database_app_pass=${DATABASE_APP_PASS:-wordpress_pass}
    local database_schema_name=${DATABASE_SCHEMA_NAME:-wordpress_db}
    local database_schema_charset=${DATABASE_SCHEMA_CHARSET:-utf8mb4}
    local database_schema_collate=${DATABASE_SCHEMA_COLLATE:-utf8mb4_unicode_ci}
    

    check_vars WEB_APP_ROOT_PATH_CLIENT WEB_APP_ROOT_PATH BUILD_PATH_WORDPRESS

    local site_path="${SITE_PATH:-'/var/www/wordpress'}"


    function config_wordpress_files_database() {
        cd ${WEB_APP_ROOT_PATH_CLIENT}

        mv wp-config-sample.php wp-config.php
        sed -i "/DB_NAME/s/database_name_here/${database_schema_name}/" wp-config.php
        sed -i "/DB_USER/s/username_here/${database_app_user}/" wp-config.php 
        sed -i "/DB_PASSWORD/s/password_here/${database_app_pass}/" wp-config.php
        sed -i "/DB_HOST/s/localhost/${database_host}/" wp-config.php
        sed -i "/DB_CHARSET/s/utf8/${database_schema_charset}/" wp-config.php
        sed -i "/DB_COLLATE/s/''/'${database_schema_collate}'/" wp-config.php


        # adjusting site path permissions, owner and group
        find ${WEB_APP_ROOT_PATH_CLIENT} -type d -exec chmod 755 {} +
        find ${WEB_APP_ROOT_PATH_CLIENT} -type f -exec chmod 644 {} +
        chown www-data:www-data -R ${WEB_APP_ROOT_PATH_CLIENT}
    }

    log_message "# copy files to correct APP path <${WEB_APP_ROOT_PATH_CLIENT}>"
    if [ -d "${WEB_APP_ROOT_PATH_CLIENT}" ]; then
        # app detected
        log_message "# APP path <$WEB_APP_ROOT_PATH_CLIENT> already exists..."

        # section to force reconfigurations
        log_message "# USE 'FORCE_RECONFIG=true' to renew copy of files."
        if [ "true" == "${FORCE_RECONFIG}" ] ; then
            # force copy of files

            log_message "# creating backup of <${WEB_APP_ROOT_PATH_CLIENT}> to <${WEB_APP_ROOT_PATH}_bkp-${date_now}> ..." 
            mv -v ${WEB_APP_ROOT_PATH_CLIENT} ${WEB_APP_ROOT_PATH}_bkp-${date_now}

            log_message "# removing <${WEB_APP_ROOT_PATH_CLIENT}/> ...."
            rm -rfv ${WEB_APP_ROOT_PATH_CLIENT}/

            log_message "# forcing copy of files..."
            cp -rv ${BUILD_PATH_WORDPRESS}/wordpress/* ${WEB_APP_ROOT_PATH_CLIENT}/
            check_error $?

            config_wordpress_files_database

        else
            log_message "skipping..."
        fi

    else
        # app not detected
        log_message "# web application path <$WEB_APP_ROOT_PATH_CLIENT> not detected..."

        log_message "# copy of files..."
        mkdir -p "${WEB_APP_ROOT_PATH_CLIENT}"
        cp -rv ${BUILD_PATH_WORDPRESS}/wordpress/* ${WEB_APP_ROOT_PATH_CLIENT}/
        check_error $?

        config_wordpress_files_database

    fi

}


function config_apache() {
	log_message "## SETTING APACHE"

	check_vars SITE_HTTP_PORT SITE_HTTPS_PORT SITE_PATH_APP SITE_SSL_ENABLED SITE_NAME SITE_DOMAIN

    local site_http_port="${SITE_HTTP_PORT:-80}"
    local site_https_port="${SITE_HTTPS_PORT:-443}"

    local site_path="${SITE_PATH_APP:-'/var/www/wordpress'}"
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
    cp "/srv/config/apache/site_sample.conf" "${site_config_file_uri}"

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
    a2ensite ${site_config_file_name}
    # ln -s "${site_config_file_name}" /etc/apache2/sites-enabled/

}


function config_crontab() {
    log_message "## SETTING CRONTAB"
    ## setting crontab
    (crontab -l ; echo "0 1 * * * bash /usr/local/bin/create_backup.sh '/etc/apache2/' '/var/www/' >> /var/backups/register.log")| crontab - 
    (crontab -l ; echo "") | crontab -
}

function config_supervisor(){
    log_message "## SETTING SUPERVISOR"
    # setting supervisor

    # copy all necessary files to supervisor directory
    cp /srv/config/supervisor/*.conf /etc/supervisor/conf.d/

}


function config_server() {
    # call all functions to configure server

    config_database
    check_error $?

    config_wordpress
    check_error $?

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
