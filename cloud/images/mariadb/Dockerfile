FROM mariadb:lts-jammy
# ubuntu based: 22.04(LTS) jammy

RUN \
    apt update && \
    apt install -y net-tools iproute2 traceroute iputils-ping mtr && \
    apt install -y tcpdump nmap netcat && \
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

EXPOSE 3306/tcp

###################################################################

VOLUME /var/lib/mysql/
VOLUME /etc/mysql/
VOLUME /var/log/
VOLUME /usr/local/bin/
VOLUME /root/
VOLUME /var/spool/cron/
VOLUME /var/backups/

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
CMD ["mariadbd"]
#CMD ["/usr/sbin/cron","-f"]
