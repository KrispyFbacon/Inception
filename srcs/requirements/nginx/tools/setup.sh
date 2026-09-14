#!/bin/bash

# Stop if a command fails ('-e' exits on error, '-x' prints every command)
set -e

# Generate a self-signed SSL/TLS certificate for our domain
# -x509: Create a self-signed certificate instead of a certificate signing request
# -nodes: Do not encrypt the private key with a password
# The certificate and private key will be used by NGINX for HTTPS
# Set the certificate subject:
# CN (Common Name) identifies the domain covered by the certificate.
# UID identifies the 42 user associated with this project.
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
	-out /etc/nginx/ssl/inception.crt \
	-keyout /etc/nginx/ssl/inception.key \
	-subj "/C=PT/ST=Porto/L=Porto/O=42/OU=42/CN=$DOMAIN_NAME/UID=frbranda"

# Replace DOMAIN_NAME in the NGINX configuration template
envsubst '${DOMAIN_NAME}' \
	< /etc/nginx/nginx.conf.template \
	> /etc/nginx/nginx.conf


# Start the CMD from the Dockerfile
exec "$@"