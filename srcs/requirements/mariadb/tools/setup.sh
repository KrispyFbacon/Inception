#!/bin/bash

DB_ROOT_PASS=$(cat /run/secrets/db_root_password)
DB_PASS=$(cat /run/secrets/db_password)

# Start MariaDB briefly to set up users
service mariadb start

# Create the database and user defined in your .env
# The admin name MUST NOT contain "admin" or "administrator" [cite: 107]
mariadb -e "CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;"
mariadb -e "CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'localhost' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';"
mariadb -e "FLUSH PRIVILEGES;"

# Shut down the temporary service so 'mysqld' can take over as PID 1
mysqladmin -u root -p${DB_ROOT_PASS} shutdown

# Execute the CMD from the Dockerfile
exec "$@"