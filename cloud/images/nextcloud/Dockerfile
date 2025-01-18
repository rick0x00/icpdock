FROM nextcloud:stable
# Image hierarchy 
# debian:12-slim, 12.7-slim, bookworm-20240926-slim, bookworm-slim
# php:8.2-apache, 8.2-apache-bookworm, 8.2.24-apache, 8.2.24-apache-bookworm
# nextcloud:stable



RUN \
    apt update && \
    apt install -y net-tools iproute2 traceroute iputils-ping mtr && \
    apt install -y tcpdump nmap netcat-traditional && \
    apt install -y dnsutils && \
    apt install -y procps htop && \
    apt install -y nano vim && \
    apt install -y mc && \
#    apt install -y wget curl && \
    apt install -y cron && \
    apt install -y rsyslog
#    apt install -y unzip && \
#    apt install -y git

# Install network filters
RUN \
    apt install -y iptables nftables

# Install supervisor
RUN \
    apt install -y supervisor


RUN \
    echo "pre copy files: serial: 2"

COPY ./config/ /srv/config/

RUN \
    cp -r /srv/config/bin/* /usr/local/bin/ && \
    chmod ug+x /usr/local/bin/*


###################################################################

## set reconfigurations trigger
ENV FORCE_RECONFIG="false"
## set healthcheck execution trigger
ENV HEALTHCHECK_ENABLED="true"

###################################################################

EXPOSE 80/tcp

###################################################################

VOLUME /var/www/html
VOLUME /var/www/html/custom_apps 
VOLUME /var/www/html/config
VOLUME /var/www/html/data 
VOLUME /var/www/html/themes 

###################################################################

WORKDIR /root/


###################################################################

# interval: time between tests
# timeout: time to consider failure
# start-period: time for the container to start(failures will not be counted)
# start-interval: time between each test within "start-period"
# retries: number of failures to consider that the container is not healtly

HEALTHCHECK --interval=60s --timeout=120s --start-period=240s --retries=5 CMD /usr/local/bin/HEALTHCHECK.sh || exit 1

###################################################################

ENTRYPOINT ["/usr/local/bin/init_srv.sh"]
CMD ["apache2-foreground"]
#CMD ["/usr/sbin/cron","-f"]
