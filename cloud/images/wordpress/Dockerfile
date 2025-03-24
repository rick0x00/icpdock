FROM debian:12

# Install tools
RUN \
    apt update && \
    apt install -y net-tools iproute2 traceroute iputils-ping mtr && \
    apt install -y tcpdump nmap netcat-traditional && \
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

## Install PHP
RUN \
    apt install -y php

# Install php deps
RUN \
    apt-get install -y php-fpm php-mysql php-curl php-dom php-imagick php-mbstring php-zip php-gd php-intl php-xml -y

# Set php-fpm to listen over ethernet
RUN sed -i "s/^listen = .*/listen = 0.0.0.0:9000/" $(find /etc/php/*/fpm/pool.d -name www.conf)

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
    cd /usr/src/  && \
    wget https://raw.githubusercontent.com/wp-cli/builds/refs/heads/gh-pages/deb/$(curl -s https://raw.githubusercontent.com/wp-cli/builds/refs/heads/gh-pages/deb/php-wpcli_latest_all.deb) -O php-wpcli_latest_all.deb  && \
    apt install ./php-wpcli_latest_all.deb   && \
    alias wp="wp --allow-root"

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

# complementary vars
ENV WEB_APP_ROOT_PATH="/var/www"
ENV WEB_APP_ROOT_PATH_CLIENT="${WEB_APP_ROOT_PATH}/${SYSTEM_NAME}/${CLIENT_NAME}"

# ARG -> ENV (ARG to ENV vars transposition)
ENV BUILD_PATH_WORDPRESS="${BUILD_PATH_WORDPRESS}"

# Wordpress variables
ENV WP_PLUGINS="classic-editor google-site-kit ultimate-addons-for-gutenberg"
ENV WP_THEMES="hueman"
ENV WP_SITE_URL="${SITE_NAME}.${SITE_DOMAIN}"
ENV WP_SITE_TITLE="${CLIENT_NAME} site"
ENV WP_SITE_ADMIN_USER="sysadmin"
ENV WP_SITE_ADMIN_PASS="super_password"
ENV WP_SITE_ADMIN_EMAIL="${WP_SITE_ADMIN_USER}@${SITE_DOMAIN}"

###################################################################

VOLUME /root/
VOLUME /usr/local/bin/
VOLUME /etc/supervisor/
VOLUME /var/www/
VOLUME /var/spool/cron/
VOLUME /var/log/
VOLUME /var/backups/
VOLUME /srv/config/

###################################################################

# php-fpm port
EXPOSE 9000/tcp

###################################################################

WORKDIR ${WEB_APP_ROOT_PATH}

###################################################################

# interval: time between tests
# timeout: time to consider failure
# start-period: time for the container to start(failures will not be counted)
# start-interval: time between each test within "start-period"
# retries: number of failures to consider that the container is not healtly

HEALTHCHECK --interval=60s --timeout=120s --start-period=240s --retries=5 CMD /usr/local/bin/healthcheck.sh --process python --attempts 3 || exit 1

###################################################################

ENTRYPOINT ["/usr/local/bin/init_srv.sh"] 
#ENTRYPOINT ["/usr/sbin/cron","-f"]
#ENTRYPOINT ["sleep", "infinity"]

