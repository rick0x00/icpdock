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

# Install nginx
RUN \
    apt install -y nginx
    
# create self signed certificates
RUN \
    mkdir -p /etc/ssl/private/  && \
    mkdir -p /etc/ssl/certs/  && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=BR/ST=State/L=Province/O=xpto/OU=SRE/CN=xpto.com"  && \
    openssl dhparam -out /etc/nginx/dhparam.pem 4096

# disable server banner
RUN \
    echo "server_tokens off;" > /etc/nginx/conf.d/disable_server_banner.conf && \
    echo "more_clear_headers Server;" >> /etc/nginx/conf.d/disable_server_banner.conf

RUN \
    echo "pre copy files: serial: 5"

COPY ./config/ /srv/config/

RUN \
    cp -r /srv/config/bin/* /usr/local/bin/ && \
    chmod ug+x /usr/local/bin/*


###################################################################

## Generic Variables
ENV CLIENT_NAME="xpto"
ENV SYSTEM_NAME="nginx"

## set reconfigurations trigger
ENV FORCE_RECONFIG="false"
## set healthcheck execution trigger
ENV HEALTHCHECK_ENABLED="true"

## web server settings
ENV SITE_HTTP_PORT="80"
ENV SITE_HTTPS_PORT="443"


###################################################################

VOLUME /var/www/
VOLUME /etc/nginx/
VOLUME /etc/supervisor/

VOLUME /srv/config/
VOLUME /var/log/
VOLUME /usr/local/bin/
VOLUME /root/
VOLUME /var/backups/


###################################################################

# HTTP port
#EXPOSE 80/tcp
EXPOSE ${SITE_HTTP_PORT}/tcp

# HTTPS port
#EXPOSE 443/tcp
EXPOSE ${SITE_HTTPS_PORT}/tcp

###################################################################

WORKDIR /etc/nginx/

###################################################################

# interval: time between tests
# timeout: time to consider failure
# start-period: time for the container to start(failures will not be counted)
# start-interval: time between each test within "start-period"
# retries: number of failures to consider that the container is not healtly


HEALTHCHECK --interval=60s --timeout=120s --start-period=240s --retries=5 CMD /usr/local/bin/healthcheck.sh --process nginx --attempts 3 && /usr/local/bin/healthcheck.sh --host 127.0.0.1 --port 80 --attempts 3 || exit 1

###################################################################

ENTRYPOINT ["/usr/local/bin/init_srv.sh"] 
#CMD ["/usr/sbin/cron","-f"]
#ENTRYPOINT ["sleep", "infinity"]

