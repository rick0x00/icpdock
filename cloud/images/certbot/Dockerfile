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
    apt update && \
    apt install -y iptables nftables

# Install supervisor
RUN \
    apt update && \
    apt install -y supervisor

# Install pip
RUN \
    apt update && \
    apt install -y python3 python3-venv libaugeas0

# Install certbot
RUN \
    python3 -m venv /opt/certbot/ && \
    /opt/certbot/bin/pip Install --upgrade pip && \
    /opt/certbot/bin/pip Install certbot certbot && \
    ln -s /opt/certbot/bin/certbot /usr/bin/certbot


COPY config/ /srv/config/

RUN \
    cp /srv/config/supervisor/*.conf /etc/supervisor/conf.d/ && \
    cp /srv/config/bin/*.sh /usr/local/bin/ && \
    chmod ug+x /usr/local/bin/*

###################################################################

ENV SITE_NAME="xpto"
ENV SITE_DOMAIN="domain.tld"


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

HEALTHCHECK --interval=60s --timeout=120s --start-period=240s --retries=5 CMD /usr/local/bin/HEALTHCHECK.sh || exit 1

###################################################################

ENTRYPOINT ["/usr/local/bin/init_srv.sh"] 
#CMD ["/usr/sbin/cron","-f"]
#CMD ["apache2ctl", "-D", "FOREGROUND"]

