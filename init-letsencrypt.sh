#!/bin/bash

# Source the nginx.env file so we can use its variables here
. ./config/nginx/nginx.env

# Configurable Variables
domains=("$NGINX_SERVER_NAME")
email="$LETSENCRYPT_EMAIL" # Adding a valid address is strongly recommended
staging="$LETSENCRYPT_STAGING_MODE" # Set to 1 if testing your setup to avoid hitting request limits

# Do not touch anything else below unless you really know what you're doing!
rsa_key_size=4096
data_path="./data/certbot"

if [ -d "$data_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi

  # Re-create data path directory to ensure that it is owned by the current user
  echo "Deleting existing files in $data_path. Sudo is used in case the $data_path files are owned by root, which can occur if Docker Compose has already been previously spun-up prior to running this script."
  sudo rm -rf "$data_path"
fi

# Create data path directory
mkdir -p "$data_path"

# If SELinux is enabled and enforced on the current system, label the directory with the 'container_file_t' policy type.
if [ $(sestatus | awk '/SELinux status:/ {print $3}') == "enabled" ] && [ $(sestatus | awk '/Current mode:/ {print $3}') == "enforcing" ]; then
  echo "SELinux is enabled! Labeling $data_path with the container_file_t policy type."
  chcon -R -t container_file_t "$data_path"
fi

if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
  echo
fi

echo "### Creating dummy certificate for $domains ..."
path="/etc/letsencrypt/live/$domains"
mkdir -p "$data_path/conf/live/$domains"
docker-compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:1024 -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot
echo


echo "### Starting nginx ..."
#docker-compose up --force-recreate -d nginx
docker-compose down && . ./docker-compose-run.sh
echo

echo "### Deleting dummy certificate for $domains ..."
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domains && \
  rm -Rf /etc/letsencrypt/archive/$domains && \
  rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
echo


echo "### Requesting Let's Encrypt certificate for $domains ..."
#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal" certbot
echo

echo "### Reloading nginx ..."
docker-compose exec nginx nginx -s reload