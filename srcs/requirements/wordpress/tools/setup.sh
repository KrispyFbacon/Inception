#!/bin/bash

# Stop if a command fails ('-e' exits on error, '-x' prints every command)
set -e


# Only initialize WordPress on the first startup
if [ ! -f "/var/www/wordpress/wp-config.php" ]; then

	# Get the database and WordPress passwords from Docker's secret files
	DB_PASS=$(cat /run/secrets/db_password)
	ADMIN_PASS=$(cat /run/secrets/wp_admin_password)
	USER_PASS=$(cat /run/secrets/wp_user_password)


	# Download WordPress into the working directory
	wp core download --allow-root


	# Create the WordPress configuration file
	# Connect to the MariaDB container using its Docker hostname and port
	wp config create \
		--dbname="$SQL_DATABASE" \
		--dbuser="$SQL_USER" \
		--dbpass="$DB_PASS" \
		--dbhost="mariadb:3306" \
		--allow-root


	# Install WordPress and create the administrator account
	wp core install \
		--url="$DOMAIN_NAME" \
		--title="Inception" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$ADMIN_PASS" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--allow-root


	# Create a second WordPress user with author privileges
	wp user create \
		"$WP_USER" \
		"$WP_USER_EMAIL" \
		--role=author \
		--user_pass="$USER_PASS" \
		--allow-root


	# Install and activate the Twenty Twenty-Four theme
	wp theme install twentytwentyfour --activate --allow-root


	# Give ownership of WordPress files to PHP-FPM
	chown -R www-data:www-data /var/www/wordpress

fi


# Start the CMD from the Dockerfile
exec "$@"