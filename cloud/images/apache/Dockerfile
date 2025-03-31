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

# Install apache
RUN \
    apt install -y apache2 apache2-doc apache2-utils libapache2-mod-fcgid

# create self signed certificates
RUN \
    mkdir -p /etc/ssl/private/  && \
    mkdir -p /etc/ssl/certs/  && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt -subj "/C=BR/ST=State/L=Province/O=xpto/OU=SRE/CN=xpto.com"  && \
    openssl dhparam -out /etc/apache2/dhparam.pem 4096

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
    a2enmod proxy_fcgi && \
    a2enmod ssl && \
    a2enmod headers

RUN \
    echo "pre copy files: serial: 3"

COPY ./config/ /srv/config/

RUN \
    cp -r /srv/config/bin/* /usr/local/bin/ && \
    chmod ug+x /usr/local/bin/*


###################################################################

## general vars
ENV SYSTEM_NAME="apache"
ENV CLIENT_NAME="xpto"

## set reconfigurations trigger
ENV FORCE_RECONFIG="false"
## set healthcheck execution trigger
ENV HEALTHCHECK_ENABLED="true"

## web server settings
ENV SITE_HTTP_PORT="80"
ENV SITE_HTTPS_PORT="443"
ENV SITE_PATH_ROOT="/var/www"
ENV SITE_PATH_APP="${SITE_PATH_ROOT}/${SYSTEM_NAME}/${CLIENT_NAME}"
ENV SITE_SSL_ENABLED="false"
ENV SITE_NAME="${CLIENT_NAME}"
ENV SITE_DOMAIN="domain.tld"


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

WORKDIR /etc/apache2/

###################################################################

# interval: time between tests
# timeout: time to consider failure
# start-period: time for the container to start(failures will not be counted)
# start-interval: time between each test within "start-period"
# retries: number of failures to consider that the container is not healtly

HEALTHCHECK --interval=60s --timeout=120s --start-period=240s --retries=5 CMD /usr/local/bin/healthcheck.sh --process apache2 --attempts 3 && /usr/local/bin/healthcheck.sh --host 127.0.0.1 --port ${SITE_HTTP_PORT} --attempts 3 || exit 1

###################################################################

ENTRYPOINT ["/usr/local/bin/init_srv.sh"] 
#ENTRYPOINT ["/usr/sbin/cron","-f"]
#ENTRYPOINT ["sleep", "infinity"]

