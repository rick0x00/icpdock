#!/usr/bin/env bash

# load libraries
source /usr/local/bin/lib/message_log.lib
source /usr/local/bin/lib/check_vars.lib
source /usr/local/bin/lib/check_error.lib

log_message "====== Starting configurations of wordpress permissions ======"

#wordpress_security_files_mode="imutable"
#wordpress_security_files_mode="restrict"
wordpress_security_files_mode=${WP_SECURITY_FILES_MODE:-permissive}

wordpress_modifications_path="${WEB_APP_ROOT_PATH_CLIENT}/wp-content/uploads ${WEB_APP_ROOT_PATH_CLIENT}/wp-content/cache"

if check_vars WEB_APP_ROOT_PATH_CLIENT ; then
    log_message "# Setting permissions..."

    # enhance security
    # restrict wordpress files
    EXCLUDED_DIRS=" -path ${WEB_APP_ROOT_PATH_CLIENT}/.git "

    function set_exclude_dirs() {
        for path in ${wordpress_modifications_path}; do
            EXCLUDED_DIRS="$EXCLUDED_DIRS -o -path ${path}"
        done    
    }
    function set_default_permissions() {
        find ${WEB_APP_ROOT_PATH_CLIENT}/ \( $EXCLUDED_DIRS \) -prune -o -type d -exec chmod 755 {} \;
        find ${WEB_APP_ROOT_PATH_CLIENT}/ \( $EXCLUDED_DIRS \) -prune -o -type f -exec chmod 644 {} \; 
    }
    function set_allow_modification_directories() {
        for path in ${wordpress_modifications_path}; do
            chown -R www-data:www-data ${path}
        done    
    }  

    if [[ "$wordpress_security_files_mode" == "permissive" ]]; then
        log_message "# file permissions mode: ${wordpress_security_files_mode}"

        #set_exclude_dirs
        set_default_permissions
        find ${WEB_APP_ROOT_PATH_CLIENT}/ \( $EXCLUDED_DIRS \) -prune -o -exec chown www-data:www-data {} \;

    elif [[ "$wordpress_security_files_mode" == "restrict" ]]; then
        log_message "# file permissions mode: ${wordpress_security_files_mode}"

        set_exclude_dirs
        set_default_permissions
        find ${WEB_APP_ROOT_PATH_CLIENT}/ \( $EXCLUDED_DIRS \) -prune -o -exec chown root:www-data {} \;
        set_allow_modification_directories

    elif [[ "$wordpress_security_files_mode" == "imutable" ]]; then
        log_message "# file permissions mode: ${wordpress_security_files_mode}"

        #set_exclude_dirs
        set_default_permissions
        find ${WEB_APP_ROOT_PATH_CLIENT}/ \( $EXCLUDED_DIRS \) -prune -o -exec chown root:www-data {} \;
        #set_allow_modification_directories
    else
        log_message "# file permissions modo not defined: apply 'imutable' mode"

        #set_exclude_dirs
        set_default_permissions
        find ${WEB_APP_ROOT_PATH_CLIENT}/ \( $EXCLUDED_DIRS \) -prune -o -exec chown root:www-data {} \;
        #set_allow_modification_directories
    fi

    # allow uploads
    #chown -R www-data:www-data ${WEB_APP_ROOT_PATH_CLIENT}/wp-content/uploads

    # grant .git correct permissions
    #chown -R root:root ${WEB_APP_ROOT_PATH_CLIENT}/.git
    #chmod 750 ${WEB_APP_ROOT_PATH_CLIENT}/.git
else
    log_message "# skip setting of permissions"
fi
