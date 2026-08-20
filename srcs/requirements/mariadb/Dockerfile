# Use Debian 12 as the base image (penultimate stable version)
FROM debian:bookworm


# Install the MariaDB server
# Remove the downloaded package lists afterwards to keep the image smaller and save space
RUN apt-get update && apt-get install -y \
	mariadb-server \
	&& rm -rf /var/lib/apt/lists/*


# Create the directory used by MariaDB for its runtime files
# Give the mysql user ownership of MariaDB's runtime and database directories
# We avoid chmod 777 to follow the principle of least privilege
# chown USER:GROUP DIRECTORY
RUN mkdir -p /var/run/mysqld && \
	chown -R mysql:mysql /var/run/mysqld && \
	chown -R mysql:mysql /var/lib/mysql


# Copy our MariaDB configuration into the image (Must end in .cnf)
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf


# Copy the initialization script into the image
# Make the script executable so it can be used as the container entrypoint
COPY tools/setup.sh /usr/local/bin/mariadb_setup.sh
RUN chmod +x /usr/local/bin/mariadb_setup.sh


# MariaDB listens on port 3306 by default
EXPOSE 3306


# Run the initialization script when the container starts
ENTRYPOINT ["/usr/local/bin/mariadb_setup.sh"]


# Start the MariaDB server in the foreground
# Listen on all interfaces so other containers can connect to MariaDB
CMD ["mariadbd"]



# https://docs.docker.com/
# https://nginx.org/en/docs/
# https://make.wordpress.org/cli/
# https://mariadb.com/docs