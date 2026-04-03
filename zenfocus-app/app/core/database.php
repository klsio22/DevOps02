<?php

declare(strict_types=1);

function app_config(): array
{
    static $config = null;

    if ($config === null) {
        $config = require __DIR__ . '/config.php';
    }

    return $config;
}

function db_connect(): mysqli
{
    $db = app_config()['db'];

    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

    $connection = new mysqli(
        $db['host'],
        $db['username'],
        $db['password'],
        $db['database'],
        (int) $db['port']
    );

    $connection->set_charset($db['charset']);

    ensure_tasks_table($connection);

    return $connection;
}

function ensure_tasks_table(mysqli $connection): void
{
    $connection->query(
        "CREATE TABLE IF NOT EXISTS tasks (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(180) NOT NULL,
            pomodoros_estimated INT NOT NULL DEFAULT 1,
            pomodoros_completed INT NOT NULL DEFAULT 0,
            status ENUM('todo', 'active', 'done') NOT NULL DEFAULT 'todo',
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )"
    );
}

function escape_html(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
}
