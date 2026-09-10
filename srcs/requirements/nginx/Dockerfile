# Use Debian 12 as the base image (penultimate stable version)
FROM debian:bookworm


# Install NGINX web server and OpenSSL for HTTPS/TLS certificates
# Remove the downloaded package lists afterwards to keep the image smaller and save space
RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	gettext-base \
	&& rm -rf /var/lib/apt/lists/*


# Create the directory used by NGINX to store our SSL certificate and private key
RUN mkdir -p /etc/nginx/ssl


# Copy the NGINX configuration template into the image
# The template contains ${DOMAIN_NAME}, which is replaced at container startup
COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template


# Copy the script used to configure and start NGINX
COPY tools/setup.sh /setup.sh
RUN chmod +x /setup.sh


# NGINX will receive HTTPS connections on port 443
EXPOSE 443


# Configure and start NGINX
ENTRYPOINT ["/setup.sh"]


# Start NGINX in the foreground
# "daemon off;" prevents NGINX from going into the background
# Keeping NGINX in the foreground allows Docker to keep the container running
CMD ["nginx", "-g", "daemon off;"]