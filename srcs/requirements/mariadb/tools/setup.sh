#!/bin/bash

# Stop if a command fails ('-e' exits on error, '-x' prints every command)
set -ex


# Get the database passwords from Docker's secret files.
DB_ROOT_PASS=$(cat /run/secrets/db_root_password)
DB_PASS=$(cat /run/secrets/db_password)



# Initialize MariaDB only on the first startup.
if [ ! -d "/var/lib/mysql/mysql" ]; then

    # Start MariaDB temporarily so we can run the initial SQL commands.
    service mariadb start


    # Wait for the database to wake up, but give up after 30 seconds
    TIMEOUT=30
    while ! mariadb-admin ping -h localhost --silent; do

        TIMEOUT=$((TIMEOUT - 1))

        if [ "$TIMEOUT" -eq 0 ]; then
            echo "Error: MariaDB took too long to start."
            exit 1
        fi

        sleep 1

    done


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

fi


# Start the CMD from the Dockerfile
exec "$@"