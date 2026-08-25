#!/bin/bash

# Stop if a command fails ('-e' exits on error, '-x' prints every command)
set -ex


if [ ! -f "wp-config.php" ]; then

fi


# Start the CMD from the Dockerfile
exec "$@"