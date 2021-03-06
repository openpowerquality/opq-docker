#!/usr/bin/env bash

# Set additional environment variables for Docker-Compose that cannot be defined in the .env file.
# When 'docker-compose up' is invoked, Compose automatically looks for environment variables set in the shell and
# substitutes them into the docker-compose.yml configuration file.
# See: https://docs.docker.com/compose/compose-file/#variable-substitution

# Source and export NGINX_SERVER_NAME for Nginx and View services in docker-compose.yml. Passed on to View as ROOT_URL.
. ./config/nginx/nginx.env
export NGINX_SERVER_NAME

# View Config Environment Var
export METEOR_SETTINGS=$(cat ./config/view/view.config.json)

# Makai Config Environment Var
export MAKAI_SETTINGS=$(cat ./config/makai/makai.config.json)
export ACQUISITION_BROKER_SETTINGS=$(cat ./config/makai/acquisition_broker.config.json)
export TRIGGERING_BROKER_SETTINGS=$(cat ./config/makai/triggering_broker.config.json)
export BOX_UPDATE_SERVER_SETTINGS=$(cat ./config/box-update-server/box-update-server.config.json)
export HEALTH_SETTINGS=$(cat ./config/health/health.config.json)

# Mauka Config Environment Var
export MAUKA_SETTINGS=$(cat ./config/mauka/mauka.config.json)

# Startup Docker-Compose. Note: Be sure that docker-compose.yml is same directory as this script.
docker-compose up -d --remove-orphans
