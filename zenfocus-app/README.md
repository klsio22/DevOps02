# OrbitVale Systems CRUD

Independent CRUD web application in pure PHP + HTML/CSS, fully isolated from `zenfocus-gitea`.

## Architecture

- Separate project folder and compose stack
- Dedicated MariaDB instance (`db` service)
- One table only: `service_requests`
- Future integration boundary: REST API over HTTP

## Stack

- PHP 8.2 + Apache (no frameworks)
- HTML/CSS only (no frontend frameworks)
- MariaDB 11
- Docker Compose (isolated)

## Database table

`service_requests` fields:

1. `id` (INT, PK, auto increment)
2. `client_name` (VARCHAR 120)
3. `contact_email` (VARCHAR 150)
4. `request_topic` (VARCHAR 150)
5. `request_status` (ENUM: open, in_progress, closed)
6. `requested_date` (DATE)

## Run with Docker

```bash
docker compose up -d --build
```

Access the app at:

- `http://localhost:8081/index.php`

Database exposed locally on:

- `localhost:3307`

## Services

- `app`: PHP + Apache (`Dockerfile`)
- `db`: MariaDB + auto schema import from `schema.sql`

## Pages

- `index.php` (Read + Delete)
- `create.php` (Create)
- `edit.php` (Update)

The logo appears on all pages via `includes/header.php`.
