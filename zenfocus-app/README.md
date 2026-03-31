# PulseFocus Tasks

Pomodoro-style task CRUD web application by ChronaPulse Labs.

## Isolation rule

- This project is independent from `zenfocus-gitea`
- It has its own `docker-compose.yml` and MariaDB instance
- No runtime communication with other stacks

## Branding

- Company: `ChronaPulse Labs`
- Tool: `Pomofocus`
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

## Files

- `index.php`: timer central + lista de tarefas + create/focus/delete
- `edit.php`: task update form
- `create.php`: dedicated task create form
- `assets/js/main.js`: timer regressivo + acoes da home + confirmacao de exclusao
- `assets/css/main.css`: layout visual da aplicacao
- `schema.sql`: database and table creation

No authentication and no reports module are included.
