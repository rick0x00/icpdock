#!/usr/bin/env bash

# load libraries
source /usr/local/bin/lib/message_log.lib
source /usr/local/bin/lib/check_vars.lib
source /usr/local/bin/lib/check_error.lib

log_message "====== Starting wordpress update ======"

function update_wordpress() {
    log_message "# update wordpress..."
    
    log_message "  - update WP CLI..."
    wp --allow-root --path="${WEB_APP_ROOT_PATH_CLIENT}" cli update
    #su - www-data -s /bin/bash -c "wp --path=\"${WEB_APP_ROOT_PATH_CLIENT}\" cli update"

    log_message "  - update CORE..."
    su - www-data -s /bin/bash -c "wp --path=\"${WEB_APP_ROOT_PATH_CLIENT}\" core update"

    log_message "  - update Plugins..."
    su - www-data -s /bin/bash -c "wp --path=\"${WEB_APP_ROOT_PATH_CLIENT}\" plugin update --all"

    log_message "  - update Themes..."
    su - www-data -s /bin/bash -c "wp --path=\"${WEB_APP_ROOT_PATH_CLIENT}\" theme update --all"
}

function disable_automatic_updates() {
    log_message "# disable automatic updates..."

    su - www-data -s /bin/bash -c "wp --path=\"${WEB_APP_ROOT_PATH_CLIENT}\" config set WP_AUTO_UPDATE_CORE false"
    su - www-data -s /bin/bash -c "wp --path=\"${WEB_APP_ROOT_PATH_CLIENT}\" plugin auto-updates disable --all"
    su - www-data -s /bin/bash -c "wp --path=\"${WEB_APP_ROOT_PATH_CLIENT}\" theme auto-updates disable --all"

}

if check_vars WEB_APP_ROOT_PATH_CLIENT ; then
    log_message "# updating wordpress..."
    default_variable_value=${WP_SECURITY_FILES_MODE}
    export WP_SECURITY_FILES_MODE="permissive"
    /usr/local/bin/config_wordpress_permissions.sh 

    update_wordpress
    disable_automatic_updates

    export WP_SECURITY_FILES_MODE="${default_variable_value}"
    /usr/local/bin/config_wordpress_permissions.sh 
else
    log_message "# skip wordpress update, variable not defined <WEB_APP_ROOT_PATH_CLIENT>"
fi
