#!/bin/bash

echo "make certificate"
SITE_NAME="blog"
SITE_DOMAIN="domain.tld"

FQDN="${SITE_NAME:+${SITE_NAME}.}${SITE_DOMAIN}"

EMAIL="sysadmin@${SITE_DOMAIN}"

WEBROOT_PATH="/var/www/letsencrypt"

CLOUDFLARE_API_FILE="/etc/letsencrypt/.secrets/cloudflare/api_token${FQDN}.ini"
CLOUDFLARE_API_TOKEN=""
if [ -z $CLOUDFLARE_API_TOKEN ] ; then
    echo "Enter Your API token"
    read CLOUDFLARE_API_TOKEN
fi

if [ -z $CLOUDFLARE_API_TOKEN ] && [ -z $CLOUDFLARE_API_FILE ]; then
    mkdir -p $(dirname ${CLOUDFLARE_API_FILE})
    echo "$CLOUDFLARE_API_TOKEN" > $CLOUDFLARE_API_FILE
else
    echo "# ERROR: variables not defined"
    echo " CLOUDFLARE_API_FILE = $CLOUDFLARE_API_FILE"
    echo " CLOUDFLARE_API_TOKEN = $CLOUDFLARE_API_TOKEN"
fi



#### SPECIFIC domain
# automatic(The ${FQDN}/.well-known/acme-challenge/ endpoint needs to be accessible on the WWW)(independent of webserver)
certbot certonly --webroot -w $WEBROOT_PATH -d "$FQDN" --agree-tos --non-interactive --text --email "${EMAIL}"

# automatic(The ${FQDN}/.well-known/acme-challenge/ endpoint needs to be accessible on the WWW)(nginx webserver)
certbot certonly --nginx -d "$FQDN" --agree-tos --non-interactive --text --email "${EMAIL}"

# automatic(cloudflare based)
certbot certonly --dns-cloudflare --dns-cloudflare-credentials ${CLOUDFLARE_API_FILE} --dns-cloudflare-propagation-seconds 60 -d "$FQDN" --agree-tos --non-interactive --text --email "${EMAIL}"

#### WILDCARD domain
# manual(Example: BIND9 server)
certbot certonly --manual --preferred-challenges dns -d "*.${SITE_DOMAIN}" -d "${SITE_DOMAIN}" --email "${EMAIL}"

# automatic(cloudflare based)
certbot certonly --dns-cloudflare --dns-cloudflare-credentials ${CLOUDFLARE_API_FILE} --dns-cloudflare-propagation-seconds 60 -d "*.${SITE_DOMAIN}" -d "${SITE_DOMAIN}" --agree-tos --non-interactive --text --email "${EMAIL}"

### cloudflare mode....