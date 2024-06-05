#!/bin/bash

echo "make certificate"

FQDN="${SITE_NAME}.${SITE_DOMAIN}"

certbot certonly --webroot -w /var/www/wordpress/ -d "${FQDN}" --agree-tos --email "henrique@domain.tld" --non-interactive --text