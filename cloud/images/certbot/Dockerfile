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

# Install pip
RUN \
    apt install -y python3 python3-pip python3-venv libaugeas0

# Install certbot
RUN \
    python3 -m venv /opt/certbot/ && \
    /opt/certbot/bin/pip install --upgrade pip && \
    /opt/certbot/bin/pip install certbot certbot-nginx certbot-apache certbot-dns-cloudflare && \
    ln -s /opt/certbot/bin/certbot /usr/bin/certbot

RUN echo 10;

COPY ./config/ /srv/config/
#COPY ./../scripts/healthcheck.sh /srv/config/bin/
#COPY ./../scripts/backup.sh /srv/config/bin/

RUN \
    cp -r /srv/config/bin/* /usr/local/bin/ && \
    chmod ug+x /usr/local/bin/*

###################################################################

## Generic Variables
ENV CLIENT_NAME="xpto"
ENV SYSTEM_NAME="certbot"

ENV STARTUP_PROVISION_CERTIFICATE="false"

## Certbot Variables

ENV CERTBOT_CERTIFICATE_TYPE=""
ENV CERTBOT_CERTIFICATE_PLUGIN=""
ENV CERTBOT_CERTIFICATE_SITE_NAME=""
ENV CERTBOT_CERTIFICATE_SITE_DOMAIN=""
ENV CERTBOT_CERTIFICATE_EMAIL=""
ENV CERTBOT_CERTIFICATE_WEBROOT=""
ENV CERTBOT_CERTIFICATE_API_TOKEN=""  

## set reconfigurations trigger
ENV FORCE_RECONFIG="false"
## set healthcheck execution trigger
ENV HEALTHCHECK_ENABLED="true"


###################################################################

VOLUME /etc/letsencrypt/
VOLUME /etc/supervisor/

VOLUME /srv/config
VOLUME /var/log/
VOLUME /usr/local/bin/
VOLUME /root/

###################################################################


###################################################################

WORKDIR /etc/letsencrypt/

###################################################################

# interval: time between tests
# timeout: time to consider failure
# start-period: time for the container to start(failures will not be counted)
# start-interval: time between each test within "start-period"
# retries: number of failures to consider that the container is not healtly

HEALTHCHECK --interval=60s --timeout=120s --start-period=240s --retries=5 CMD /usr/local/bin/healthcheck.sh --process cron --attempts 3 || exit 1

###################################################################

ENTRYPOINT ["/usr/local/bin/init_srv.sh"] 
#CMD ["/usr/sbin/cron","-f"]
#CMD ["apache2ctl", "-D", "FOREGROUND"]

