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

### 3.2 Volume Management

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











## 5. Initial Setup
 
### 5.1 Clone the repository
 
```bash
git clone <repo-url> inception
cd inception
```
 
### 5.2 Configure `.env`
 
Edit `srcs/.env` and set `DOMAIN_NAME`, `SQL_DATABASE`, `SQL_USER`, and `DATA_PATH` for your environment. If you're deploying under a different domain or want data stored elsewhere on the host, this is the only file you need to change.
 
### 5.3 Create secrets
 
```bash
mkdir -p secrets/mariadb secrets/wordpress
 
echo "your_db_password"      > secrets/mariadb/db_password
echo "your_db_root_password" > secrets/mariadb/db_root_password
echo "your_wp_admin_password" > secrets/wordpress/wp_admin_password
echo "your_wp_user_password"  > secrets/wordpress/wp_user_password
```
 
Each file must contain only its corresponding password, with no extra whitespace or newlines beyond what your editor/shell adds.
 
### 5.4 Configure the domain
 
NGINX serves the site under `frbranda.42.fr`, so that hostname needs to resolve to your local machine:
 
```bash
echo "127.0.0.1 frbranda.42.fr" | sudo tee -a /etc/hosts
```
 
Without this entry, requests to `https://frbranda.42.fr` won't reach the container — the domain has no public DNS record, it only resolves locally via `/etc/hosts`.
 
---
 
## 6. Build, Launch & Management
 
### 6.1 Makefile targets
 
| Command | Purpose |
|---|---|
| `make` | Build images and start all containers |
| `make down` | Stop and remove containers |
| `make clean` | Remove containers and networks, keep images and data |
| `make fclean` | Remove containers, images, volumes, and persistent data under `DATA_PATH` |
| `make re` | `fclean` followed by a full rebuild and restart |
 
**Warning:** `make fclean` deletes the persistent data directories under `DATA_PATH`. Don't run it unless you intend to lose the current WordPress/MariaDB data.
 
### 6.2 Equivalent Docker Compose commands
 
If you want to work without the Makefile:
 
```bash
docker compose -f srcs/docker-compose.yml up -d --build   # build and start
docker compose -f srcs/docker-compose.yml down             # stop and remove
docker compose -f srcs/docker-compose.yml ps               # container status
docker compose -f srcs/docker-compose.yml logs             # all logs
```
 
### 6.3 Day-to-day inspection
 
```bash
docker ps                     # running containers
docker images                 # built images
docker volume ls              # named volumes
docker network ls             # networks
 
docker logs nginx
docker logs wordpress
docker logs mariadb
docker logs -f wordpress      # follow logs live
 
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
 
docker inspect nginx
docker inspect wordpress
docker inspect mariadb
```
 
`docker exec` is primarily useful for debugging — e.g. checking a config file was copied correctly, or running a command inside the container's actual environment.
 
---
 
 
## 9. Volumes and Persistent Data
 
Two named Docker volumes hold persistent data:
 
- `mariadb_vol` → `${DATA_PATH}/mariadb`
- `wordpress_vol` → `${DATA_PATH}/wordpress`
With the current `.env`, that resolves to:
 
```
/home/frbranda/data/mariadb
/home/frbranda/data/wordpress
```
 
These are named volumes configured with bind-mount driver options — so `docker volume ls` and `docker volume inspect` treat them as regular managed volumes, but the underlying data is physically stored at a predictable, directly inspectable path on the host rather than buried in Docker's internal storage directory.
 
```bash
docker volume ls
docker volume inspect mariadb_vol
docker volume inspect wordpress_vol
```
 
**Important distinction:**
- Removing or recreating containers (`make down`, `make clean`) does **not** touch this data — the volumes persist independently of the containers.
- `make fclean` removes the volumes **and** the data under `DATA_PATH` — this is destructive and cannot be undone.
---
 
## 10. Credentials Management
 
Four credentials exist, split between the database and WordPress:
 
| File | Used for |
|---|---|
| `secrets/mariadb/db_root_password` | MariaDB root account |
| `secrets/mariadb/db_password` | The `SQL_USER` application account WordPress connects with |
| `secrets/wordpress/wp_admin_password` | WordPress administrator login |
| `secrets/wordpress/wp_user_password` | WordPress regular (non-admin) user login |
 
All four are stored as plain-text files on the host under `secrets/` and mounted read-only inside their respective containers under `/run/secrets/`.
 
**To change a credential for a fresh install:** edit the relevant file under `secrets/` before running `make` (or after a `make fclean`, which wipes existing data) — the new value will be picked up the next time MariaDB/WordPress initialize.
 
**To change a credential after the stack is already running:** editing the secret file alone is not enough. MariaDB and WordPress only read secrets during their *initial* setup — the database user and WordPress accounts are already created with the old password. You'd need to update the password inside the running service itself (e.g. `ALTER USER` in MariaDB, or through `wp user update` via WP-CLI for WordPress accounts) in addition to updating the secret file, so the two stay in sync.
 
---
 
## 11. Testing and Verification
 
### 11.1 Check containers are running
 
```bash
docker ps
```
 
Expected: `nginx`, `wordpress`, and `mariadb` all show `Up`, with `mariadb` showing `(healthy)` once its healthcheck passes.
 
### 11.2 Check HTTPS
 
```bash
curl -k -I https://frbranda.42.fr
```
 
Expected: `HTTP/1.1 200 OK`. The `-k` flag is required because the certificate is self-signed, so `curl` doesn't trust it by default.
 
### 11.3 Check the certificate and TLS version
 
```bash
openssl s_client -connect frbranda.42.fr:443 </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```
 
Confirm the negotiated protocol is TLSv1.2 or TLSv1.3 (shown in the `openssl s_client` output) and that older protocols are rejected.
 
### 11.4 Check MariaDB health
 
```bash
docker inspect --format='{{.State.Health.Status}}' mariadb
```
 
Expected: `healthy`.
 
### 11.5 Check networking
 
```bash
docker network ls
docker network inspect inception
```
 
Confirm all three containers appear as members of the same network.
 
### 11.6 Check persistence
 
1. Make a change in WordPress (e.g. create a test post).
2. `make down` then `make up` (or `make re`).
3. Confirm the change is still there — this verifies data survives container recreation.
### 11.7 Check port exposure
 
```bash
docker ps
```
 
Only `nginx` should show a host-published port mapping (`0.0.0.0:443->443/tcp`); `wordpress` and `mariadb` should show their ports without a host mapping, confirming they aren't reachable from outside the Docker network.
 
---
 
## 12. Troubleshooting
 
**MariaDB keeps restarting**
```bash
docker logs mariadb
```
Common causes: incorrect or missing secrets, a database initialization error, incorrect file permissions on `${DATA_PATH}/mariadb`, or leftover incompatible data from a previous run (try `make fclean` if you're in a throwaway dev environment).
 
**WordPress can't connect to MariaDB**
```bash
docker logs wordpress
docker logs mariadb
```
Confirm MariaDB is healthy (§11.4) and that WordPress is using `mariadb:3306` and the credentials matching `SQL_USER`/`db_password`.
 
**Site isn't reachable**
```bash
docker ps
docker logs nginx
getent hosts frbranda.42.fr
```
Confirm NGINX is up, its logs don't show a config error, and the domain resolves to `127.0.0.1`.
 
**Browser shows a certificate warning**
Expected — the project uses a self-signed certificate rather than one from a public CA, so browsers will always flag it as untrusted. This isn't a bug.
 
---
 
---
 
## 14. Development & Customization
 
- **NGINX config:** `srcs/requirements/nginx/conf/`
- **WordPress setup/tools:** `srcs/requirements/wordpress/tools/`
- **MariaDB init/config:** `srcs/requirements/mariadb/conf/`
- **Build instructions:** each service's `Dockerfile` under `srcs/requirements/<service>/`
- **Service definitions, network, volumes:** `srcs/docker-compose.yml`
- **Non-sensitive configuration:** `srcs/.env`
After changing a Dockerfile, a config file that's copied at build time, or `docker-compose.yml`, rebuild the affected image(s):
 
 ```bash
 make
 ```
 
---
