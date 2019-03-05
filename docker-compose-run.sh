#!/usr/bin/env bash

# Set additional environment variables for Docker-Compose that cannot be defined in the .env file.
# When 'docker-compose up' is invoked, Compose automatically looks for environment variables set in the shell and
# substitutes them into the docker-compose.yml configuration file.
# See: https://docs.docker.com/compose/compose-file/#variable-substitution

# View Config Environment Var
export METEOR_SETTINGS=$(cat ./config/view/view.config.json)

# Makai Config Environment Var
export MAKAI_SETTINGS=$(cat ./config/makai/makai.config.json)

# Startup Docker-Compose. Note: Be sure that docker-compose.yml is same directory as this script.
docker-compose up -d --remove-orphans
