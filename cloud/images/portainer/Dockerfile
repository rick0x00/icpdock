FROM portainer/portainer-ce:alpine


# Install tools
RUN \
    apk update && \
    apk add bash && \
    apk add net-tools traceroute mtr && \
    apk add tcpdump nmap netcat-openbsd && \
    apk add bind-tools && \
    apk add procps htop && \
    apk add nano vim && \
    apk add mc && \
    apk add wget curl && \
    apk add apk-cron && \
    apk add rsyslog 


# Install network filters
RUN \
    apt install -y iptables nftables

# Install supervisor
RUN \
    apt install -y supervisor

    
RUN \
    echo "pre copy files: serial: 6"

COPY ./config/ /srv/config/

RUN \
    cp -r /srv/config/bin/* /usr/local/bin/ && \
    chmod ug+x /usr/local/bin/*

###################################################################

## set healthcheck execution trigger
ENV HEALTHCHECK_ENABLED="true"

###################################################################

VOLUME /data

###################################################################

# HTTP port
EXPOSE 9000/tcp

# HTTPS port
EXPOSE 9443/tcp

###################################################################

WORKDIR /data

###################################################################

# interval: time between tests
# timeout: time to consider failure
# start-period: time for the container to start(failures will not be counted)
# start-interval: time between each test within "start-period"
# retries: number of failures to consider that the container is not healtly

HEALTHCHECK --interval=60s --timeout=120s --start-period=240s --retries=5 CMD /usr/local/bin/healthcheck.sh --process portainer --attempts 3 && /usr/local/bin/healthcheck.sh --host 127.0.0.1 --port 9000 --attempts 3 || exit 1

###################################################################

ENTRYPOINT ["/usr/local/bin/init_srv.sh"]

#ENTRYPOINT ["/usr/sbin/cron","-f"]
#ENTRYPOINT ["sleep", "infinity"

