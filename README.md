*This project has been created as part of the 42 curriculum by frbranda.*

# Inception
![Docker](https://storage.googleapis.com/star-lab/blog/OGs/docker.png)


## Description
This project aims to develop system administration skills by building a small web infrastructure with Docker and Docker Compose. The goal is to deploy a WordPress website using separate containers for NGINX, WordPress/PHP-FPM, and MariaDB.

Each service has a specific role and communicates with the others through a dedicated Docker bridge network. NGINX is the only service directly accessible from the host, while WordPress and MariaDB remain accessible only through the Docker network. Persistent website and database data are stored on the host, and sensitive credentials are handled using Docker secrets.


## Architecture Overview

- **NGINX** — acts as the web server and the only service exposed to the host. It handles `HTTPS` connections on port `443` (`TLSv1.2`/`TLSv1.3` only) and forwards `PHP` requests to `WordPress` through `FastCGI`.
- **WordPress** — provides the web application and runs with `PHP-FPM` in a dedicated container, separate from `NGINX`.
- **MariaDB** — provides the database used by `WordPress` and listens on port `3306` for connections from other containers on the Docker network. The port is not published to the host.

The services are connected through a dedicated Docker bridge network. Only `NGINX` exposes a port to the host; ports `9000` (PHP-FPM) and `3306` (MariaDB) remain internal to the Docker network.

Persistent data is stored using two named Docker volumes, `mariadb_vol` and `wordpress_vol`. These volumes are configured to use directories on the host defined by the `DATA_PATH` variable in `.env`. Therefore, `MariaDB` data is stored in `${DATA_PATH}/mariadb` and `WordPress` data in `${DATA_PATH}/wordpress`. This keeps the persistent data outside the containers and at a predictable location on the host.


```text
                    HTTPS :443
                        │
                        ▼
                  ┌───────────┐
                  │   NGINX   │
                  │    :443   │
                  └─────┬─────┘
                        │
                   FastCGI :9000
                        │
                        ▼
                 ┌──────────────┐
                 │   WordPress  │
                 │   PHP-FPM    │
                 │     :9000    │
                 └──────┬───────┘
                        │
                   MariaDB :3306
                        │
                        ▼
                 ┌──────────────┐
                 │   MariaDB    │
                 │     :3306    │
                 └──────────────┘

               Custom Docker Network
```


## Features

- Three separate Docker containers for NGINX, WordPress/PHP-FPM, and MariaDB
- HTTPS with TLSv1.2/TLSv1.3
- Custom Docker bridge network
- Persistent WordPress and MariaDB data
- Docker secrets for sensitive credentials
- Automatic container restart policies
- MariaDB healthcheck and WordPress dependency management
- PHP requests handled through FastCGI


## Instructions

### Requirements
 
- A `Linux` environment (physical machine or Virtual Machine)
- `Docker` and `Docker Compose` installed
- `make`


### Setup

The domain is configured through the `DOMAIN_NAME` variable in `srcs/.env` and should follow the project requirement `<login>.42.fr`.

1. Clone the repository:
    ```bash
    git clone <repo-url> inception
    cd inception
    ```

2. Ensure your `.env` file is properly configured inside the `srcs/` directory.

3. Create the following password files under a `secrets/` directory at the project `root`. Each file should contain only the corresponding raw password as plain text:

    ```
    secrets/
    ├── mariadb/
    │   ├── db_password
    │   └── db_root_password
    └── wordpress/
        ├── wp_admin_password
        └── wp_user_password
    ```

    **Security:** The .env file and Docker secret files contain environment-specific configuration and credentials and are excluded from version control through .gitignore. Never commit actual passwords or secret files to the repository.

4. Add `127.0.0.1 <login>.42.fr` to your host machine's hosts file. This makes `<login>.42.fr` resolve to your local machine, allowing the domain to be used to access the website. On `Linux`, the hosts file is located at `/etc/hosts`:
    ```bash
    echo "127.0.0.1 <login>.42.fr" | sudo tee -a /etc/hosts
    ```

For detailed configuration, customization, and troubleshooting, see `DEV_DOC.md`.

### Build & Run
 
```bash
make            # builds the images and starts all containers
make down       # stops and removes the containers
make clean      # stops and removes containers and networks, keeping images and data
make fclean     # WARNING: removes containers, images, volumes and persistent data under DATA_PATH
make re         # completely resets and rebuilds the project
```
 
Once running, the site is reachable at:
 
```
https://<login>.42.fr
```
 
### Verifying the setup
 
For detailed service, networking, database, WordPress, HTTPS, and persistence tests, see `DEV_DOC.md`.


## Documentation

 For information about customizing the configuration, understanding the infrastructure, or using the deployed `WordPress` service, refer to the documentation below.

* [`USER_DOC.md`](USER_DOC.md) — explains how to use and manage the deployed WordPress service.
* [`DEV_DOC.md`](DEV_DOC.md) — provides detailed information about the Docker architecture, configuration, customization, development, and troubleshooting.


## Project Architecture & Technical Choices

The following choices were made to keep the infrastructure separated, lightweight, and manageable.

* **Virtual Machines vs Docker:** Virtual machines require a complete guest operating system, which generally results in higher resource usage. Docker containers share the host operating system kernel and isolate applications at the process level, generally resulting in lower overhead and faster startup times.

* **Secrets vs Environment Variables:** Environment variables are convenient for passing non-sensitive configuration, such as the domain name, but they are not ideal for storing passwords. Docker Secrets allow sensitive credentials to be provided to containers as files rather than being stored directly in environment variables. In this project, database and WordPress passwords are therefore provided through Docker Secrets, while non-sensitive configuration is kept in environment variables.

* **Docker Network vs Host Network:** This project utilizes a custom Docker bridge network, providing internal DNS that allows containers to resolve each other by service name (e.g., `wordpress` can connect to `mariadb`), while keeping internal ports (`3306`, `9000`) inaccessible from the host.

* **Docker Volumes vs Bind Mounts:** Standard Docker named volumes are managed entirely by the Docker daemon inside its own internal storage directory, which is portable but abstracts away exactly where data lives on disk. Plain bind mounts map an exact host path into the container, giving full visibility but rigidly tying the setup to that specific path. This project combines both approaches: it uses named volumes (`mariadb_vol`, `wordpress_vol`) configured with bind-mount driver options. This allows the data to be managed safely as a Docker volume while remaining physically stored at a predictable, inspectable path on the host, dynamically set by the `DATA_PATH` variable in the `.env` file.


## Resources
- [Docker official documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker secrets documentation](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/docs)
- [WordPress CLI documentation](https://make.wordpress.org/cli/)
- [WordPress official documentation](https://wordpress.org/documentation/)


- **AI Usage:** Generative AI assistants, including Gemini, ChatGPT, and Claude, were used throughout the project as interactive study and research tools. They helped clarify system administration concepts such as Docker networking, PID 1 processes, container restart policies, data persistence, bind mounts, and Docker secrets. They were also used to review configuration files, troubleshoot issues, organize testing steps, and improve the structure and clarity of the project documentation. All project components were reviewed, tested, and understood by the author.
