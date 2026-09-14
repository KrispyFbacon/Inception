# Inception — User Documentation

This file explains how end users or administrators can interact with the Inception infrastructure.

## Services Provided

The infrastructure provides a WordPress website using three services:

* **NGINX**: Web server that handles incoming HTTPS connections.
* **WordPress**: Content management system used to provide and manage the website.
* **MariaDB**: Database service used by `WordPress` to store website data.



## How to Start and Stop the Project

From the root directory of the project:

1. **Start the project:**

   ```bash
   make
   ```

2. **Stop the project:**

   ```bash
   make down
   ```

   This stops and removes the project containers without removing the persistent website or database data.

3. **Stop the project and remove all project data:**

   ```bash
   make fclean
   ```

   This removes the project containers, images, volumes, and persistent website and database data. Use this only when a complete reset is intended.



## Accessing the Website and Administration Panel

The website is available at the domain configured by the `DOMAIN_NAME` variable in `srcs/.env`.

The domain must follow the project requirement:

```text
<login>.42.fr
```

The WordPress administration panel is available at:

```text
https://<login>.42.fr/wp-admin
```

The project uses a self-signed SSL certificate, so the browser may display a security warning when accessing the website. This is expected.



## Locating and Managing Credentials

The password files used as `Docker secrets` are stored `secrets/` directory:

```text
secrets/
├── mariadb/
│   ├── db_password
│   └── db_root_password
└── wordpress/
    ├── wp_admin_password
    └── wp_user_password
```

These files contain the passwords used by `MariaDB` and `WordPress`.

The `secrets/` directory must not be committed to the repository.

## Checking the Services

To check whether the services are running correctly:

```bash
make status
```

The three containers should be running:

```text
nginx
wordpress
mariadb
```

`MariaDB` should report a `healthy` status.

To check for service errors, view the logs with:

```bash
make logs
```

Individual container logs can also be checked with:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

