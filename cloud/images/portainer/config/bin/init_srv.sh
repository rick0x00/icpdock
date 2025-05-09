#!/usr/bin/env bash
ARGS="$*"

# load libraries
source /usr/local/bin/lib/message_log.lib
source /usr/local/bin/lib/check_vars.lib
source /usr/local/bin/lib/check_error.lib

# setting of server
#/usr/local/bin/config_srv.sh
check_error $?

log_message "------------------------------------------------------"
log_message "########            STARTING SERVER           ########"
log_message "------------------------------------------------------"

# setting DNS
/usr/local/bin/config_dns.sh
check_error $?

log_message "#### STARTING SERVICES ####"

log_message "## starting supervisor..."
/usr/bin/python3 /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n & 

#/usr/sbin/cron -f
#sleep infinity

log_message "## starting portainer..."
/portainer


# log_message "## starting default services..."
# /usr/local/bin/docker-entrypoint.sh ${args}
