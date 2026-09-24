# MySQL dev database

MySQL 9.7 (LTS) running in Docker, intended for local development.
Everything lives in the [DB/](DB/) folder — just the official image, no custom build.

## Run

```bash
cd DB
docker compose up
```

Run it **in the foreground** (do not add `-d`). The first run downloads the image (~600 MB)
and takes a bit longer to initialize.

## Stop

- Press `Ctrl+C`, **or**
- just close the terminal — Compose stops the container together with the terminal session.

The database will **not** start on system boot or after a crash (`restart: "no"`).

## Configuration

Values live in `DB/.env` (see `DB/.env.example` for a template):

| Variable | Default | Meaning |
|---|---|---|
| `MYSQL_ROOT_PASSWORD` | `YourStrong!Passw0rd` | root password |
| `MYSQL_DATABASE` | `AppDb` | database created automatically on first start |

## Connection

```
Host:     127.0.0.1
Port:     3306
User:     root
Password: value of MYSQL_ROOT_PASSWORD from DB/.env
Database: AppDb
```

JDBC URL example:

```
jdbc:mysql://127.0.0.1:3306/AppDb
```

## Data

Data is stored in the named Docker volume `mysql_data`, so it survives
`Ctrl+C` / closing the terminal / `docker compose down`.

To wipe everything and start from scratch:

```bash
cd DB
docker compose down -v
```
