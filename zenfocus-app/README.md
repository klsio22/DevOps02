# pulsefocus-app

Pomodoro-style task CRUD web application by ChronaPulse Labs.

Project name: `pulsefocus-app`

## Isolation rule

- This project is independent from `zenfocus-gitea`
- It has its own `docker-compose.yml` and MariaDB instance
- No runtime communication with other stacks

## Branding

- Company: `ChronaPulse Labs`
- Tool: `PulseFocus`
- Domain reference: `focus.chronapulse.com.br`

## Stack

- Backend: pure PHP (no frameworks)
- Frontend: HTML/CSS + Vanilla JS
- Database: MariaDB 11
- Runtime: Docker Compose (app + db)

## Main table

Table: `tasks`

1. `id` (INT, PK, auto increment)
2. `title` (VARCHAR 180)
3. `pomodoros_estimated` (INT)
4. `pomodoros_completed` (INT)
5. `status` (ENUM: todo, active, done)
6. `created_at` (TIMESTAMP)

This project keeps only one table and one CRUD domain (`tasks`).

## Run

```bash
docker compose up -d --build
```

Application URL:

- `http://localhost:8081/index.php`

MariaDB exposed locally:

- `localhost:3307`

## Project structure

- `public/`: only web-exposed directory
- `public/index.php`: timer home + tasks list + quick CRUD actions
- `public/create.php` and `public/edit.php`: task forms
- `public/actions/`: public entrypoints that delegate to backend actions
- `public/assets/css/main.css`: visual layout
- `public/assets/js/main.js`: timer and UI interactions
- `app/core/config.php`: app and DB config (+ `.env` fallback)
- `app/core/database.php`: DB connection and helpers
- `app/actions/`: backend CRUD handlers
- `views/partials/`: reusable view fragments
- `database/schema.sql`: schema bootstrap used by Docker

No authentication and no reports module are included.
