#!/usr/bin/env bash

# set if test are executed
HEALTHCHECK_EXECUTE="${HEALTHCHECK_ENABLED:-true}"

# control of loop testes
MAX_ATTEMPTS=3
WAIT_TIME=5

# setting log files
STATUS_LOG_FILE="/var/log/healthcheck_status.log"
REGISTER_LOG_FILE="/var/log/healthcheck_register.log"

# setting trigger file
BYPASS_TRIGGER="/var/log/healthcheck_trigger"
# if exists tests are not executed

# var control of success of tests
SUM_STATUS=0

# load libraries
# source /usr/local/bin/lib/message_log.lib
# source /usr/local/bin/lib/check_vars.lib
# source /usr/local/bin/lib/check_error.lib

# register log functions
log_message() {
    local register_log="${REGISTER_LOG_FILE}"
    local message="$*"
    local content_log="[$(date '+%Y-%m-%d %H:%M:%S')] : $message"
    echo "${content_log}" >> "${register_log}"
    echo "${content_log}" 
}


# check vars function
function check_vars(){
	log_message "# checking vars"
	for var_name in "$@"; do
		if [ -z "${!var_name}" ]; then
			log_message "Error: variable \"$var_name\" is not defined"
			exit 1
		fi
	done
	log_message "# All variables are defined"
}

# check error function
function check_error() {
    local return_code=$*
    if [ $return_code -eq 0 ]; then
        log_message "# Execution: OK"
    else
        log_message "# Execution: ERROR"
        exit 1
    fi
}

bypass_control() {
    log_message "# bypass checking.."
    
    local bypass_execute=0
    
    # check if healphcheck are defined on variable
    if  [[ "${HEALTHCHECK_EXECUTE}" == "true" ]] || [[ "${HEALTHCHECK_EXECUTE}" == "TRUE" ]] ; then
	    log_message "# HEALTHCHECK_EXECUTE=${HEALTHCHECK_EXECUTE}."
	    bypass_execute=$(($bypass_execute + 0))
    else
	    log_message "# HEALTHCHECK_EXECUTE=${HEALTHCHECK_EXECUTE}."
        bypass_execute=$(($bypass_execute + 1))
    fi

    # check if trigger file exists
    if  [[ -f "${BYPASS_TRIGGER}" ]]; then
	    log_message "# BYPASS FILE(${BYPASS_TRIGGER}) ALREADY EXISTS."
        bypass_execute=$(($bypass_execute + 1))
    else
	    log_message "# BYPASS FILE(${BYPASS_TRIGGER}) NOT EXISTS."
        bypass_execute=$(($bypass_execute + 0))
    fi

    # conclusion of tests
    if [[ "${bypass_execute}" == "0" ]]; then
	    log_message "# SKIPPING bypass..."
        HEALTHCHECK_EXECUTE="true"
    else
	    log_message "# EXECUTING bypass..."
	    HEALTHCHECK_EXECUTE="false"
    fi
}


exec_tests() {
    log_message "# STARTING TESTS..."

    # internal function to sum status code
    sum_status() {
        local status="$1"
        SUM_STATUS=$(($SUM_STATUS + $status))
    }

    # process execution function
    check_process() {
        local process_name="$1"
        log_message "# checking if process <$process_name> is running"
        pgrep "$process_name" &>> ${REGISTER_LOG_FILE}
        if [[ "$?" == "0" ]]; then
            log_message "# process <$process_name> IS RUNNING."
            sum_status 0
        else
            log_message "# process <$process_name> NOT RUNNING."
            sum_status 1
        fi
    }

    # Open ports function
    check_port() {
        local host="$1"
        local port="$2"
        log_message "# checking if port <${port}> on host <${host}> is open"
        # tcp test
        nc -z -v -w 5 "$host" "$port" &>> ${REGISTER_LOG_FILE}
        local stdout_1=$?
        # udp test
        nc -z -v -w 1 "$host" -u "$port" &>> ${REGISTER_LOG_FILE}
        local stdout_2=$?
        if [[ "$stdout_1" == "0" ]] || [[ "$stdout_2" == "0" ]] ; then
            log_message "# Port <${port}> on host <${host}> is OPEN"
            sum_status 0
        else
            log_message "# Port <${port}> on host <${host}> is CLOSED"
            sum_status 1
        fi
    }

    # url responding test
    check_url() {
        local url="$1"
        log_message "# checking if <${url}> is responding"
        local http_code=$(curl -s --insecure --head  -w "%{http_code}" "${url}" &>> ${REGISTER_LOG_FILE})
        if [[ "$?" == "0" ]]; then
            #log_message "# the <$url> RESPONDING"
            #sum_status 0
            if [[ $http_code =~ ^[23][0-9]{2}$ ]]; then
                log_message "# the <$url> RESPONDING (HTTP $http_code)"
                sum_status 0
            else
                log_message "# the <$url> NOT RESPONDING (HTTP $http_code)"
                sum_status 1
            fi
        else
            log_message "# the <$url> NOT RESPONDING"
            sum_status 1
        fi
    }

    log_message " STARTING TESTS..."
    # loop of attempts
    for attempt in $(seq 1 ${MAX_ATTEMPTS}); do
        log_message " attempt ${attempt}..."
        # restart SUM_STATUS to always step
        SUM_STATUS=0


        if [[ -n "$PROCESS_NAME" ]]; then
            check_process "$PROCESS_NAME"
        fi

        if [[ -n "$HOST" && -n "$PORT" ]]; then
            check_port "$HOST" "$PORT"
        fi

        if [[ -n "$URL" ]]; then
            check_url "$URL"
        fi

        # # check process Apache
        # check_process "apache2"

        # # check process Supervisor
        # #check_process "supervisord"
        # check_process "python"

        # # check ports: https
        # #check_port "localhost" "54200"
        # check_port "127.0.0.1" "${SITE_HTTP_PORT}"


        # # check HTTP service
        # #check_url "http://localhost:$HTTP_PORT"
        # check_url "http://127.0.0.1:${SITE_HTTP_PORT}"


        # if sum of return test is ZERO, exit of loop
        if [ "$SUM_STATUS" -eq 0 ]; then
            log_message " SUCESS ON ALL TESTS..."
            break
        fi
        log_message " FAIL ON TESTS, RESTARTING..."

        # wait before next test
        sleep "$WAIT_TIME"
    done
}

log_message "============================================================================="
log_message "###### Start execution script $0"





# Initialize variables
PROCESS_NAME=""
HOST=""
PORT=""
URL=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --process)
            PROCESS_NAME="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --url)
            URL="$2"
            shift 2
            ;;
        --attempts)
            MAX_ATTEMPTS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done





log_message "# HEALTHCHECK_EXECUTE=${HEALTHCHECK_EXECUTE}"



# checking bypass
bypass_control

if [[ "${HEALTHCHECK_EXECUTE}" == "true" ]] ||  [[ "${HEALTHCHECK_EXECUTE}" == "TRUE" ]] ; then
    log_message "# GO TO TESTS..."

    # executing Tests
    exec_tests
    
    # check all status code and register
    if [ "$SUM_STATUS" -eq 0 ]; then
        log_message "# SUCCESS ON TESTS"
        log_message "# REGISTERING '0' ON <$STATUS_LOG_FILE>"

        echo "0" > "$STATUS_LOG_FILE"
    else
        log_message "# FAIL ON TESTS"
        log_message "# REGISTERING '1' ON <$STATUS_LOG_FILE>"

        echo "1" > "$STATUS_LOG_FILE"
    fi
else
    log_message "# SKIPPING TESTS..."
    # case of use on bypass

    # false value by bypass
    log_message " REGISTERING '0' ON <$STATUS_LOG_FILE>"

    echo "0" > "$STATUS_LOG_FILE"
fi

# WITTING STATUS CODE
RETURN_CODE=$(cat $STATUS_LOG_FILE)

exit $RETURN_CODE
log_message "============================================================================="
