#!/bin/bash

# Stop if a command fails ('-ex' prints every command)
set -ex

# Get the database passwords from Docker's secret files.
DB_ROOT_PASS=$(cat /run/secrets/db_root_password)
DB_PASS=$(cat /run/secrets/db_password)


# Start MariaDB temporarily so we can run the initial SQL commands.
service mariadb start



# Create the database that will be used by WordPress.
mariadb -e "CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;"

# Create the WordPress user (database account).
# '%' allows the account to connect from another container.
mariadb -e "CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"

# Give the WordPress user access to the database
mariadb -e "GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';"

# Set the password for MariaDB's root account.
mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';"

# Apply the privilege changes
mariadb -u root -p"${DB_ROOT_PASS}" -e "FLUSH PRIVILEGES;"



# Stop the temporary MariaDB server
mariadb-admin -u root -p"${DB_ROOT_PASS}" shutdown


# Start the CMD from the Dockerfile
exec "$@"