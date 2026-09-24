# MSSQL dev database

SQL Server 2025 (Developer edition) running in Docker, intended for local development.
Everything lives in the [DB/](DB/) folder — no custom image, just the official one.

## Run

```bash
cd DB
docker compose up
```

Run it **in the foreground** (do not add `-d`). The first run downloads the image (~1.7 GB).

## Stop

- Press `Ctrl+C`, **or**
- just close the terminal — Compose stops the container together with the terminal session.

The database will **not** start on system boot or after a crash (`restart: "no"`).

## Configuration

The sa password is set in `DB/.env` (see `DB/.env.example` for a template).

## Connection

```
Server:   localhost,1433
Login:    sa
Password: value of MSSQL_SA_PASSWORD from DB/.env
```

Example connection string:

```
Server=localhost,1433;Database=AppDb;User Id=sa;Password=YourStrong!Passw0rd;TrustServerCertificate=True;
```

## Data

Data is stored in the named Docker volume `mssql_data`, so it survives
`Ctrl+C` / closing the terminal / `docker compose down`.

To wipe everything and start from scratch:

```bash
cd DB
docker compose down -v
```
