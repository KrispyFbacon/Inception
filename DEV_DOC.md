# Inception — Developer Documentation
 
This document explains how to set up, build, manage, and troubleshoot the Inception infrastructure.
 
---
 
## 1. Environment Setup
 
### 1.1 Prerequisites
 
Install the following before setting up the project:
 
- A Linux environment (physical machine or VM)
- Docker
- Docker Compose
- `make`
- `git`

Verify each is installed:

```bash
docker --version
docker compose version
make --version
git --version
```

---

### 1.2 Project Structure
 
```
inception/
├── Makefile
├── README.md
├── DEV_DOC.md
├── USER_DOC.md
├── .gitignore
├── secrets/
│   ├── mariadb/
│   │   ├── db_password
│   │   └── db_root_password
│   └── wordpress/
│       ├── wp_admin_password
│       └── wp_user_password
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   └── tools/
        └── nginx/
            ├── Dockerfile
            └── conf/
```
 
### 1.3 Configuration
 
The project uses `srcs/.env` for non-sensitive configuration:
 
```
DOMAIN_NAME=frbranda.42.fr

DATA_PATH=/home/frbranda/data

SQL_DATABASE=wordpress_db
SQL_USER=wp_user

WP_ADMIN_USER=frbranda
WP_ADMIN_EMAIL=frbranda@example.com
WP_USER=author
WP_USER_EMAIL=author@example.com
```
 
| Variable | Purpose |
|---|---|
| `DOMAIN_NAME` | Domain configured for the WordPress site and used as the project domain.|
| `DATA_PATH` | Base directory on the host where the persistent MariaDB and WordPress data is stored.|
| `SQL_DATABASE` | Name of the MariaDB database created for WordPress.|
| `SQL_USER` | Non-root MariaDB user used by WordPress to access the database.|
| `WP_ADMIN_USER` | Username of the WordPress administrator account created during initialization.|
| `WP_ADMIN_EMAIL` | Email address associated with the WordPress administrator account.|
| `WP_USER` | Username of the additional WordPress user created during initialization.|
| `WP_USER_EMAIL` | Email address associated with the additional WordPress user.|

---

### Example .env Configuration

The following shows the main non-sensitive values that can be customized:

```env
# Domain Settings
DOMAIN_NAME=<your_login>.42.fr

# Base path on the host where persistent MariaDB and WordPress data is stored.
DATA_PATH=/home/<your_login>/data

# MariaDB Settings
SQL_DATABASE=wordpress_db
SQL_USER=wp_user

# WordPress Settings
WP_ADMIN_USER=admin_name
WP_ADMIN_EMAIL=admin@example.com
WP_USER=author_name
WP_USER_EMAIL=author@example.com
``` 

Passwords are intentionally not stored in `.env`; they are managed through Docker secrets in §1.6.


### 1.4 Changing the Domain

The default configuration uses `frbranda.42.fr`. To use a different domain, update `DOMAIN_NAME` in `srcs/.env`:

```env
DOMAIN_NAME=example.42.fr
```
The corresponding hostname must also be mapped to the local machine in `/etc/hosts`:

```text
127.0.0.1 example.42.fr
```

`DOMAIN_NAME` is substituted into the NGINX configuration and the self-signed certificate's `CN` automatically at container startup. No manual edits to the NGINX configuration or Dockerfile are required.

After changing the domain-related configuration, rebuild the project:

```bash
make re
```

A full reset is recommended for an existing installation because the WordPress site URL is stored in the database during initialization.


### 1.5 Changing the Data Location

`DATA_PATH` determines the base directory on the host where persistent project data is stored:


```env
DATA_PATH=/home/<your_login>/data
```

The corresponding directories are:

```text
/home/<your_login>/data/mariadb
/home/<your_login>/data/wordpress
```

These directories are used as the host-side storage for the named Docker volumes `mariadb_vol` and `wordpress_vol`. The volumes use Docker's local volume driver with bind-mount options, so Docker manages them as named volumes while the actual data is stored at the location defined by `DATA_PATH`.

Because the data is stored outside the containers, it survives container removal with `make down` and rebuilds that do not call `make fclean`.

The data is deleted by `make fclean`. `make re` also deletes the data because it runs `make fclean` before rebuilding the project.

Changing `DATA_PATH` does not automatically move existing data. If existing data needs to be preserved, it must be moved or copied to the new location before starting the project with the new path.

### 1.6 Docker Secrets
 
Credentials are provided as Docker secrets rather than environment variables. Docker Compose mounts them inside the containers as files under `/run/secrets/`:
 
```
secrets/
├── mariadb/
│   ├── db_password
│   └── db_root_password
└── wordpress/
    ├── wp_admin_password
    └── wp_user_password
```
 
Each file contains only the raw password, nothing else. The corresponding paths inside the containers are:
 
```
/run/secrets/db_password
/run/secrets/db_root_password
/run/secrets/wp_admin_password
/run/secrets/wp_user_password
```
 
**Security:** `.env` and `secrets/` are excluded from version control via `.gitignore`. Never commit real passwords or secret files.
 
---
 
## 2. Build and Launch

### 2.1 Build and Start

From the project root, run:

```bash
make
```

This builds the Docker images and starts all services in detached mode.

To check that the containers are running:

```bash
make status
```

The expected services are:

- `nginx`
- `wordpress`
- `mariadb`


### 2.2 Stop the Project

```bash
make down
```

Stops and removes the containers while preserving images and persistent data.

For a complete reset:

```bash
make fclean
```

**Warning**: `make fclean` removes the containers, network, all project images, Docker volumes, and the persistent data under `DATA_PATH`. The next `make` or `make re` will rebuild the required images from scratch.


### 2.3 Rebuild the Project

```bash
make re
```

**Warning**: `make re` removes the containers, network, all project images, Docker volumes, and the persistent data under `DATA_PATH` before rebuilding the project.


### 2.4 View Logs

To view logs from all services:

```bash
make logs
```

To inspect a specific container directly:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

---

## 3. Project Management

### 3.1 Makefile Commands

| Command | Purpose |
|---|---|
| `make` | Same as `make up`: create data directories, then build and start all containers. |
| `make build` | Build the Docker images without starting the containers. |
| `make up` | Create the persistent data directories, then build and start all containers. |
| `make down` | Stop and remove the containers and network. Persistent data and images are kept. |
| `make stop` | Stop the running containers without removing them. |
| `make start` | Start stopped containers. |
| `make restart` | Restart the containers. |
| `make logs` | Display logs from all services. |
| `make status` | Display the current status of the containers. |
| `make clean` | Same as `make down`, with a confirmation message.|
| `make fclean` | Completely reset the project by removing containers, images, volumes, and persistent data. |
| `make re` | Perform a complete reset with `fclean`, then build and start the project again. |

---

### 3.2 Equivalent Docker Compose Commands
 
The Makefile is a convenience wrapper: every target ultimately calls `docker compose` against `srcs/docker-compose.yml`. If you want to work without the Makefile, the equivalent commands are:
 
```bash
docker compose -f srcs/docker-compose.yml up -d --build   # build and start
docker compose -f srcs/docker-compose.yml down             # stop and remove
docker compose -f srcs/docker-compose.yml ps               # container status
docker compose -f srcs/docker-compose.yml logs             # all logs
```
 
### 3.3 Container Inspection
 
Beyond the Makefile/Compose commands above, these Docker commands are useful for direct inspection and debugging.
 
**Inspect a container**
 
```bash
docker ps                     # is it running?
docker logs -f wordpress      # follow its logs live
docker inspect wordpress      # full config: health, restart policy, network
```
 
Use these to check a specific container's state — whether it's up, what it's currently logging, and its complete configuration.
 
**Inspect Docker resources**
 
```bash
docker images                 # built images
docker volume ls              # named volumes
docker network ls             # networks
```
 
Use these to see what Docker has built or created for the project as a whole, independent of any single container.
 
**Open a shell inside a container**
 
```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```
 
Useful for debugging — e.g. checking that a config file was copied correctly, or running a command inside the container's actual environment.


### 3.4 Volume Management

The project defines two named Docker volumes:

- mariadb_vol
- wordpress_vol

Docker Compose prefixes these names with the project name. With the current configuration, the actual Docker volume names are:

```text
srcs_mariadb_vol
srcs_wordpress_vol
```

List the Docker volumes:

```bash
docker volume ls
```

Inspect a volume's configuration:

```bash
docker volume inspect srcs_mariadb_vol
docker volume inspect srcs_wordpress_vol
```

The inspection output can be used to verify the host-side storage location configured through `DATA_PATH`.

With the default configuration:

- `srcs_mariadb_vol`    → `/home/frbranda/data/mariadb`
- `srcs_wordpress_vol`  → `/home/frbranda/data/wordpress`

---

## 4. Troubleshooting
 
Common first steps when something isn't working:
 
- **A service won't start / exits immediately**: check its logs with `make logs` or `docker logs -f <container>` for the exact error.
- **A container doesn't come back after a crash**: confirm its restart policy with `docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' <container>` — it should be set to restart automatically (e.g. `always` or `unless-stopped` in `docker-compose.yml`).
- **WordPress can't reach the database**: confirm `mariadb` is up and healthy (`docker ps`, `docker inspect mariadb`), and check the credentials under `/run/secrets/` inside the `wordpress` container with `docker exec -it wordpress bash`. All three services share a single Docker network and reach each other by service name (`mariadb`, `wordpress`, `nginx`), not by IP.
- **Site loads with the wrong domain / certificate mismatch**: confirm `DOMAIN_NAME` in `srcs/.env` matches the entry added to `/etc/hosts`, then run `make re` (site URLs are stored in the database at initialization, so a partial rebuild won't update them).
- **Changes to `.env` or secrets don't seem to apply**: restart or rebuild the affected services so they read the updated configuration. For a completely fresh initialization, use `make re` — note that this deletes persistent data.
- **Data looks reset unexpectedly**: check whether `make fclean` or `make re` was run recently — both remove the volumes and everything under `DATA_PATH`.

 ---

## 5. Development & Customization
 
- **NGINX config:** `srcs/requirements/nginx/conf/`
- **WordPress setup/tools:** `srcs/requirements/wordpress/tools/`
- **MariaDB init/config:** `srcs/requirements/mariadb/conf/`
- **Build instructions:** each service's `Dockerfile` under `srcs/requirements/<service>/`
- **Service definitions, network, volumes:** `srcs/docker-compose.yml`
- **Non-sensitive configuration:** `srcs/.env`

After changing a Dockerfile, a configuration file copied at build time, or docker-compose.yml, rebuild and restart the project:

 ```bash
 make
 ```
 
---
