# Variables
NAME = inception
DATA_PATH = /home/frbranda/data
COMPOSE = docker compose -f srcs/docker-compose.yml

all: up	

build:
	$(COMPOSE) build

up:
	@echo "Creating data directories..."
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	@echo "Building and starting containers..."
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs

status:
	$(COMPOSE) ps


# Stops containers and removes them, but leaves the images and database data intact
clean: down
	@echo "Containers and networks successfully removed."


# Completely reset the Inception environment:
# Remove containers, network, volumes, images, host data folders and persistent data.
fclean:
	@echo "Removing host data folders (requires sudo)..."
	@sudo rm -rf $(DATA_PATH)
	@echo "Wiping Docker images and volumes..."
	$(COMPOSE) down -v --rmi all
	@echo "Complete nuclear wipe finished."


re: fclean all

.PHONY: all build up down stop start restart logs status clean fclean re