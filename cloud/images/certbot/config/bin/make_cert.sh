#!/bin/bash
#
# Usage:
#   ./make_cert.sh -t {specific|wildcard} -p {webroot|nginx|cloudflare|manual} -d SITE_DOMAIN [options]
#
# Options:
#   -t, --type           Certificate type: specific or wildcard (default: specific)
#   -p, --plugin         Plugin to use:
#                        * For specific certificates: webroot, nginx, or cloudflare.
#                        * For wildcard certificates: manual or cloudflare.
#   -s, --site-name      SITE_NAME (optional; if not provided, FQDN becomes SITE_DOMAIN)
#   -d, --site-domain    SITE_DOMAIN (required)
#   -e, --email          Email for registration (optional; default: sysadmin@SITE_DOMAIN)
#   -w, --webroot        Webroot path for the webroot plugin (optional; default: /var/www/letsencrypt)
#   -a, --api-token      Cloudflare API token (required if plugin is cloudflare)
#   -h, --help           Display this help message
#

# Function to display usage instructions.
usage() {
  echo "Usage: $0 -t {specific|wildcard} -p {webroot|nginx|cloudflare|manual} -d SITE_DOMAIN [options]"
  echo ""
  echo "Options:"
  echo "  -t, --type           Certificate type: specific or wildcard (default: specific)"
  echo "  -p, --plugin         Plugin to use:"
  echo "                         * For specific: webroot, nginx, or cloudflare"
  echo "                         * For wildcard: manual or cloudflare"
  echo "  -s, --site-name      SITE_NAME (optional; if omitted, FQDN will be SITE_DOMAIN)"
  echo "  -d, --site-domain    SITE_DOMAIN (required)"
  echo "  -e, --email          Email for registration (default: sysadmin@SITE_DOMAIN)"
  echo "  -w, --webroot        Webroot path (default: /var/www/letsencrypt)"
  echo "  -a, --api-token      Cloudflare API token (required if plugin is cloudflare)"
  echo "  -h, --help           Display this help message"
}

# Set default values.
CERT_TYPE="specific"   # specific or wildcard
PLUGIN=""
SITE_NAME=""
SITE_DOMAIN=""
EMAIL=""
WEBROOT_PATH="/var/www/letsencrypt"
CLOUDFLARE_API_TOKEN=""
CLOUDFLARE_API_FILE=""

# Use getopt to parse long and short options.
TEMP=$(getopt -o t:p:s:d:e:w:a:h --long type:,plugin:,site-name:,site-domain:,email:,webroot:,api-token:,help -n "$0" -- "$@")
if [ $? != 0 ]; then
  usage
  exit 1
fi

# Note: The following "eval set --" is required to properly parse the arguments.
eval set -- "$TEMP"
#set -- "$TEMP"


while true; do
  case "$1" in
    -t|--type)
      CERT_TYPE="$2"
      shift 2
      ;;
    -p|--plugin)
      PLUGIN="$2"
      shift 2
      ;;
    -s|--site-name)
      SITE_NAME="$2"
      shift 2
      ;;
    -d|--site-domain)
      SITE_DOMAIN="$2"
      shift 2
      ;;
    -e|--email)
      EMAIL="$2"
      shift 2
      ;;
    -w|--webroot)
      WEBROOT_PATH="$2"
      shift 2
      ;;
    -a|--api-token)
      CLOUDFLARE_API_TOKEN="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Validate required parameters.
if [ -z "$SITE_DOMAIN" ]; then
  echo "Error: SITE_DOMAIN is required."
  usage
  exit 1
fi

if [ -z "$EMAIL" ]; then
  EMAIL="sysadmin@${SITE_DOMAIN}"
fi

# Build the FQDN based on whether SITE_NAME is provided.
FQDN="${SITE_NAME:+${SITE_NAME}.}${SITE_DOMAIN}"

# For Cloudflare plugin, ensure the API token is provided.
if [ "$PLUGIN" = "cloudflare" ]; then
  if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "Error: Cloudflare plugin selected but API token is not provided."
    usage
    exit 1
  fi
  CLOUDFLARE_API_FILE="/srv/config/letsencrypt/.secrets/cloudflare/api_token${FQDN}.ini"
  mkdir -p "$(dirname "$CLOUDFLARE_API_FILE")"
  echo "dns_cloudflare_api_token = $CLOUDFLARE_API_TOKEN" > "$CLOUDFLARE_API_FILE"
  chmod 600 "$CLOUDFLARE_API_FILE"
fi

echo "------------------------------------"
echo "Certificate Type: $CERT_TYPE"
echo "Plugin:          $PLUGIN"
echo "FQDN:            $FQDN"
echo "Email:           $EMAIL"
echo "------------------------------------"

# Execute the appropriate Certbot command based on certificate type and plugin.
if [ "$CERT_TYPE" = "specific" ]; then
  # Specific certificate for a single domain.
  case "$PLUGIN" in
    webroot)
      certbot certonly --webroot -w "$WEBROOT_PATH" -d "$FQDN" --agree-tos --non-interactive --text --email "$EMAIL"
      ;;
    nginx)
      certbot certonly --nginx -d "$FQDN" --agree-tos --non-interactive --text --email "$EMAIL"
      ;;
    cloudflare)
      certbot certonly --dns-cloudflare --dns-cloudflare-credentials "$CLOUDFLARE_API_FILE" --dns-cloudflare-propagation-seconds 60 -d "$FQDN" --agree-tos --non-interactive --text --email "$EMAIL"
      ;;
    *)
      echo "Error: For specific certificate, choose a valid plugin: webroot, nginx, or cloudflare."
      usage
      exit 1
      ;;
  esac

elif [ "$CERT_TYPE" = "wildcard" ]; then
  # Wildcard certificate requires a DNS challenge.
  case "$PLUGIN" in
    manual)
      certbot certonly --manual --preferred-challenges dns -d "*.${SITE_DOMAIN}" -d "${SITE_DOMAIN}" --email "$EMAIL"
      ;;
    cloudflare)
      certbot certonly --dns-cloudflare --dns-cloudflare-credentials "$CLOUDFLARE_API_FILE" --dns-cloudflare-propagation-seconds 60 -d "*.${SITE_DOMAIN}" -d "${SITE_DOMAIN}" --agree-tos --non-interactive --text --email "$EMAIL"
      ;;
    *)
      echo "Error: For wildcard certificates, choose either manual or cloudflare plugin."
      usage
      exit 1
      ;;
  esac

else
  echo "Error: Invalid certificate type. Choose either specific or wildcard."
  usage
  exit 1
fi
