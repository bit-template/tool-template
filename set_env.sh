#!/bin/bash
# template/set_env.sh
# Simple environment setup script

# Prompt only if not already set
: "${DOMAIN:?Enter DOMAIN (e.g. example.com)}"
: "${SERVICE_USER:?Enter SERVICE_USER (e.g. docker)}"

# Export variables globally for this shell session
export DOMAIN
export SERVICE_USER

echo "Environment variables set:"
echo "  DOMAIN=$DOMAIN"
echo "  SERVICE_USER=$SERVICE_USER"
