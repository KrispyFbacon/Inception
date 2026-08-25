# Use Debian 12 as the base image (penultimate stable version)
FROM debian:bookworm


# Install PHP-FPM, PHP-MySQL extension, PHP CLI, and curl
# PHP-FPM executes PHP code and manages PHP worker processes
# php-mysql allows PHP/WordPress to communicate with MariaDB
# php-cli allows PHP to be run from the command line (needed by WP-CLI)
# curl is used to download WP-CLI
# Remove the downloaded package lists afterwards to keep the image smaller and save space
RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-cli \
    curl \
    && rm -rf /var/lib/apt/lists/*


# Configure PHP-FPM to listen on TCP port 9000 instead of a Unix socket
# NGINX runs in a separate container, so it cannot use PHP-FPM's local Unix socket
# Port 9000 allows NGINX to communicate with PHP-FPM through the Docker network
RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf


# Download WP-CLI, the command-line interface for WordPress
# Make the WP-CLI file executable and move it to a directory in PATH
# This allows us to use the "wp" command from our setup script
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp


# Create the directory used by PHP-FPM for its runtime files
RUN mkdir -p /run/php


# Copy the WordPress initialization script into the image
# Make the script executable so it can be used as the container entrypoint
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh


# Set the default working directory for WordPress
# Commands run after this point will use /var/www/wordpress as their current directory
WORKDIR /var/www/wordpress


# PHP-FPM listens on port 9000
# This documents the port used by PHP-FPM for communication with NGINX
EXPOSE 9000


# Run the initialization script when the container starts
ENTRYPOINT ["/usr/local/bin/setup.sh"]


# Start PHP-FPM in the foreground
# Keeping PHP-FPM in the foreground keeps the container running
CMD ["php-fpm8.2", "--nodaemonize"]