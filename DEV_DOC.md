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
| `DOMAIN_NAME` | Domain used by NGINX and WordPress. It must match the domain configured in `/etc/hosts.`|
| `DATA_PATH` | Base directory on the host where the persistent MariaDB and WordPress data is stored.|
| `SQL_DATABASE` | Name of the MariaDB database created for WordPress.|
| `SQL_USER` | Non-root MariaDB user used by WordPress to access the database.|
| `DATA_PATH` | Host directory under which persistent MariaDB and WordPress data is stored (see §9). |
| `WP_ADMIN_USER` | Username of the WordPress administrator account created during initialization.
| `WP_ADMIN_EMAIL` | Email address associated with the WordPress administrator account.
| `WP_USER` | Username of the additional WordPress user created during initialization.
| `WP_USER_EMAIL` |Email address associated with the additional WordPress user.
 
Passwords are intentionally not stored in `.env`. They are managed through Docker secrets in §4.2.
 
### 4.2 Docker Secrets
 
Credentials are provided as Docker secrets rather than environment variables, so they're passed to containers as files instead of being visible in `docker inspect` or process environments. They live on the host under `secrets/`:
 
```
secrets/
├── mariadb/
│   ├── db_password
│   └── db_root_password
└── wordpress/
    ├── wp_admin_password
    └── wp_user_password
```
 
Each file contains only the raw password, nothing else. Inside the containers, Compose mounts them under `/run/secrets/`, e.g.:
 
```
/run/secrets/db_password
/run/secrets/db_root_password
```
 
**Security:** `.env` and `secrets/` are excluded from version control via `.gitignore`. Never commit real passwords or secret files.
 
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
 
## 7. Container Architecture
 
### NGINX
 
- Built from a Debian base image, with NGINX compiled/installed rather than using the official NGINX image (per project constraints).
- Terminates HTTPS on port `443` using a self-signed certificate, restricted to TLSv1.2/TLSv1.3.
- Forwards PHP requests to WordPress over FastCGI on `wordpress:9000`.
- It's the only container with a host-published port, since it's the sole intended entry point into the stack — WordPress and MariaDB have no reason to be reachable directly from outside the Docker network.
### WordPress
 
- Contains the WordPress core files and runs PHP-FPM, listening on port `9000` for FastCGI requests from NGINX.
- Does **not** bundle NGINX — it only speaks FastCGI, it doesn't serve HTTP itself.
- Connects to MariaDB over the Docker network at `mariadb:3306` using the credentials from `SQL_USER`/`db_password`.
- WordPress installation and configuration (site URL, admin user, plugins, etc.) is automated with WP-CLI during container startup, rather than done manually through the web install wizard.
### MariaDB
 
- Runs the database server, listening on port `3306`, reachable only from other containers on the Docker network (not published to the host).
- On first startup, initializes the database (`SQL_DATABASE`), creates the application user (`SQL_USER`) using `db_password`, and sets the root password from `db_root_password`.
- Exposes a healthcheck so Compose can hold WordPress back from starting until MariaDB reports healthy, avoiding connection errors during startup.
---
 
## 8. Networking
 
```
Host
 │
 │ HTTPS :443
 ▼
NGINX
 │
 │ FastCGI :9000
 ▼
WordPress
 │
 │ MySQL/MariaDB :3306
 ▼
MariaDB
```
 
All three containers sit on a single custom Docker bridge network. Docker's built-in DNS lets each container resolve the others by service name — `wordpress` reaches MariaDB at `mariadb:3306`, and NGINX reaches WordPress at `wordpress:9000` — with no manual IP configuration needed. Ports `9000` and `3306` are exposed *between containers* on this network but are never published to the host, so nothing outside the Docker network can reach PHP-FPM or MariaDB directly.
 
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
 
## 13. Cleanup
 
| Command | Effect |
|---|---|
| `make clean` | Removes containers and networks, keeps images and data |
| `make fclean` | Removes containers, images, volumes, **and** persistent data under `DATA_PATH` |
 
**Warning:** `make fclean` is destructive and irreversible — it deletes everything under `DATA_PATH`, including the WordPress site and database contents.
 
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
or, targeting Compose directly:
```bash
docker compose -f srcs/docker-compose.yml up -d --build
```
 
---
 
## 15. Technical References
 
- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/docs)
- [WP-CLI documentation](https://make.wordpress.org/cli/)
- [WordPress documentation](https://wordpress.org/documentation/)
