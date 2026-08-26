# Use Debian 12 as the base image (penultimate stable version)
FROM debian:bookworm


# Install NGINX web server and OpenSSL for HTTPS/TLS certificates
# Remove the downloaded package lists afterwards to keep the image smaller and save space
RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	&& rm -rf /var/lib/apt/lists/*


# Create the directory used by NGINX to store our SSL certificate and private key
RUN mkdir -p /etc/nginx/ssl


# Generate a self-signed SSL/TLS certificate for our domain
# -x509: Create a self-signed certificate instead of a certificate signing request
# -nodes: Do not encrypt the private key with a password
# The certificate and private key will be used by NGINX for HTTPS
RUN openssl req -x509 -nodes \
	-out /etc/nginx/ssl/inception.crt \
	-keyout /etc/nginx/ssl/inception.key \
	-subj "/C=PT/ST=Porto/L=Porto/O=42/OU=42/CN=frbranda.42.fr/UID=frbranda"


# Copy our custom NGINX configuration into the image
# This replaces the default NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf


# NGINX will receive HTTPS connections on port 443
EXPOSE 443


# Start NGINX in the foreground
# "daemon off;" prevents NGINX from going into the background
# Keeping NGINX in the foreground allows Docker to keep the container running
CMD ["nginx", "-g", "daemon off;"]