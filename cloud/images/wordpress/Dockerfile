FROM debian:11

# Install tools
RUN \
    apt update && \
    apt install -y net-tools iproute2 traceroute iputils-ping mtr && \
    apt install -y tcpdump nmap netcat && \
    apt install -y dnsutils && \
    apt install -y procps htop && \
    apt install -y nano vim && \
    apt install -y mc && \
    apt install -y wget curl && \
    apt install -y cron && \
    apt install -y rsyslog && \
    apt install -y unzip && \
    apt install -y git

# Install network filters
RUN \
    apt install -y iptables nftables

# Install supervisor
RUN \
    apt install -y supervisor

# Install mariadb client
RUN \
    apt install -y mariadb-client

# Install apache
RUN \
    apt install -y apache2 apache2-doc apache2-utils

## Install PHP
RUN \
    apt install -y php

# Install php deps
RUN \
    apt-get install -y libapache2-mod-php php-mysql

# Disable apache directory listing
RUN \
    cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bkp_$(date +%s) && \
    sed -i "/Options/s/Indexes FollowSymLinks/FollowSymLinks/" /etc/apache2/apache2.conf

# Disable apache server banner
RUN \
    cp /etc/apache2/conf-enabled/security.conf /etc/apache2/conf-enabled/security.conf.bkp_$(date +%s) && \
    sed -i "/ServerTokens/s/OS/Prod/" /etc/apache2/conf-enabled/security.conf && \
    sed -i "/ServerSignature/s/On/Off/" /etc/apache2/conf-enabled/security.conf

##disable default apache website
RUN \
    a2dissite 000-default.conf && \
    rm -rf /var/www/html

##Enable the needed Apache modules
RUN \
    a2enmod rewrite && \
    a2enmod proxy && \
    a2enmod proxy_http && \
    a2enmod ssl && \
    a2enmod headers

# set vars of default executions build
ARG BUILD_PATH_ROOT="/usr/src"
ARG BUILD_PATH_WORDPRESS="${BUILD_PATH_ROOT}/wordpress/"

# copy a zip file of wordpress to correct destination path(if copy is not executed, dockerfile execute download of the repository)
#COPY ./local_repo/wordpress.zip ${BUILD_PATH_WORDPRESS}/wordpress.zip

RUN \
    mkdir -p "${BUILD_PATH_WORDPRESS}" && \
    if [ ! -f ${BUILD_PATH_WORDPRESS}/wordpress.zip ] ; then wget https://wordpress.org/latest.zip -O "${BUILD_PATH_WORDPRESS}/wordpress.zip" ; fi && \
    unzip "${BUILD_PATH_WORDPRESS}/wordpress.zip" -d "${BUILD_PATH_WORDPRESS}/"

RUN \
    echo "pre copy files: serial: 1"

COPY ./config/ /srv/config/

RUN \
    cp -r /srv/config/bin/* /usr/local/bin/ && \
    chmod ug+x /usr/local/bin/*


###################################################################

## general vars
ENV SYSTEM_NAME="wordpress"
ENV CLIENT_NAME="xpto"

## set reconfigurations trigger
ENV FORCE_RECONFIG="false"
## set healthcheck execution trigger
ENV HEALTHCHECK_ENABLED="true"

## database settings
ENV DATABASE_HOST="localhost"
ENV DATABASE_PORT="3306"
ENV DATABASE_CONFIG_MODE="master"
ENV DATABASE_ADMIN_USER="root"
ENV DATABASE_ADMIN_PASS=""
ENV DATABASE_APP_USER="wordpress_user"
ENV DATABASE_APP_PASS="wordpress_pass"
ENV DATABASE_SCHEMA_NAME="wordpress_db"
ENV DATABASE_SCHEMA_CHARSET="utf8mb4"
ENV DATABASE_SCHEMA_COLLATE="utf8mb4_unicode_ci"

ENV DATABASE_WORDPRESS_USER=wordpressuser
ENV DATABASE_WORDPRESS_PASS=wordpresspass

## web server settings
ENV SITE_HTTP_PORT="80"
ENV SITE_HTTPS_PORT="443"
ENV SITE_PATH_ROOT="/var/www"
ENV SITE_PATH_APP="${SITE_PATH_ROOT}/${SYSTEM_NAME}/${CLIENT_NAME}"
ENV SITE_SSL_ENABLED="false"
ENV SITE_NAME="${CLIENT_NAME}"
ENV SITE_DOMAIN="domain.tld"

# complementary vars
ENV WEB_APP_ROOT_PATH="${SITE_PATH_ROOT}"
ENV WEB_APP_ROOT_PATH_CLIENT="${SITE_PATH_APP}"

# ARG -> ENV (ARG to ENV vars transposition)
ENV BUILD_PATH_WORDPRESS="${BUILD_PATH_WORDPRESS}"


###################################################################

VOLUME /root/
VOLUME /usr/local/bin/
VOLUME /etc/supervisor/
VOLUME /etc/apache2/
VOLUME /var/www/
VOLUME /var/spool/cron/
VOLUME /var/log/
VOLUME /var/backups/
VOLUME /srv/config/

###################################################################

# HTTP port
#EXPOSE 80/tcp
EXPOSE ${SITE_HTTP_PORT}/tcp

# HTTPS port
#EXPOSE 443/tcp
EXPOSE ${SITE_HTTPS_PORT}/tcp

###################################################################

WORKDIR ${WEB_APP_ROOT_PATH}

###################################################################

# interval: time between tests
# timeout: time to consider failure
# start-period: time for the container to start(failures will not be counted)
# start-interval: time between each test within "start-period"
# retries: number of failures to consider that the container is not healtly

HEALTHCHECK --interval=60s --timeout=120s --start-period=240s --retries=5 CMD /usr/local/bin/HEALTHCHECK.sh || exit 1

###################################################################

ENTRYPOINT ["/usr/local/bin/init_srv.sh"] 
#ENTRYPOINT ["/usr/sbin/cron","-f"]
#ENTRYPOINT ["sleep", "infinity"]

